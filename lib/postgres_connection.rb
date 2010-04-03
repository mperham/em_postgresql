require 'eventmachine'
require 'postgres-pr/message'
require 'postgres-pr/connection'
require 'stringio'
require 'fiber'

class StringIO # :nodoc:
  # Reads exactly +n+ bytes.
  #
  # If the data read is nil an EOFError is raised.
  #
  # If the data read is too short a TruncatedDataError is raised and the read
  # data is obtainable via its #data method.
  def readbytes(n)
    str = read(n)
    if str == nil
      raise EOFError, "End of file reached"
    end
    if str.size < n
      raise TruncatedDataError.new("data truncated", str) 
    end
    str
  end
  alias read_exactly_n_bytes readbytes
end


module EventMachine
  module Protocols
    class PostgresConnection < EventMachine::Connection
      include PostgresPR

      def initialize
        @data = ""
        @params = {}
        @connected = false
      end
      
      # Fibered impl for synchronous execution of SQL within EM
      def exec(sql)
        fiber = Fiber.current
#        p [fiber.object_id, self.object_id, sql]
        yielding = true
        (status, result, errors) = nil
        d = query(sql)
        d.callback do |s, r, e|
          (status, result, errors) = s, r, e
          fiber.resume
        end
        d.errback do |msg|
          errors = msg
          status = false
          # errback is called from the same fiber
          yielding = false
        end
        
        Fiber.yield if yielding
#        p [fiber.object_id, self.object_id, result]
        return PGresult.new(result) if status
        raise RuntimeError, (errors || result).inspect
      end

      def close
        close_connection
      end

      def closed?
        !@connected
      end
      
      def post_init
        @connected = true
      end

      def unbind
        @connected = false
        if o = (@pending_query || @pending_conn)
          o.succeed false, "lost connection"
        end
      end

      def connect(db, user, psw=nil)
        d = EM::DefaultDeferrable.new
        d.timeout 15

        if @pending_query || @pending_conn
          d.fail "Operation already in progress"
        else
          @pending_conn = d
          prms = {"user"=>user, "database"=>db}
          @user = user
          if psw
            @password = psw
            #prms["password"] = psw
          end
          send_data PostgresPR::StartupMessage.new( 3 << 16, prms ).dump
        end

        d
      end

      def query(sql)
        d = EM::DefaultDeferrable.new
        d.timeout 15

        if !@connected
          d.fail "Not connected"
        elsif @pending_query || @pending_conn
          d.fail "Operation already in progress"
        else
          @r = PostgresPR::Connection::Result.new
          @e = []
          @pending_query = d
          send_data PostgresPR::Query.dump(sql)
        end

        d
      end

      def receive_data(data)
        @data << data
        while @data.length >= 5
          pktlen = @data[1...5].unpack("N").first
          if @data.length >= (1 + pktlen)
            pkt = @data.slice!(0...(1+pktlen))
            m = StringIO.open( pkt, "r" ) {|io| PostgresPR::Message.read( io ) }
            if @pending_conn
              dispatch_conn_message m
            elsif @pending_query
              dispatch_query_message m
            else
              raise "Unexpected message from database"
            end
          else
            break # very important, break out of the while
          end
        end
      end

      # Cloned and modified from the postgres-pr.
      def dispatch_conn_message(msg)
        case msg
        when AuthentificationClearTextPassword
          raise ArgumentError, "no password specified" if @password.nil?
          send_data PasswordMessage.new(@password).dump

        when AuthentificationCryptPassword
          raise ArgumentError, "no password specified" if @password.nil?
          send_data PasswordMessage.new(@password.crypt(msg.salt)).dump

        when AuthentificationMD5Password
          raise ArgumentError, "no password specified" if @password.nil?
          require 'digest/md5'

          m = Digest::MD5.hexdigest(@password + @user)
          m = Digest::MD5.hexdigest(m + msg.salt)
          m = 'md5' + m
          send_data PasswordMessage.new(m).dump

        when AuthentificationKerberosV4, AuthentificationKerberosV5, AuthentificationSCMCredential
          raise "unsupported authentification"

        when AuthentificationOk
        when ErrorResponse
          raise msg.field_values.join("\t")
        when NoticeResponse
          @notice_processor.call(msg) if @notice_processor
        when ParameterStatus
          @params[msg.key] = msg.value
        when BackendKeyData
          # TODO
          #p msg
        when ReadyForQuery
          # TODO: use transaction status
          pc,@pending_conn = @pending_conn,nil
          pc.succeed true
        else
          raise "unhandled message type"
        end
      end

      # Cloned and modified from the postgres-pr.
      def dispatch_query_message(msg)
        case msg
        when DataRow
          @r.rows << msg.columns
        when CommandComplete
          @r.cmd_tag = msg.cmd_tag
        when ReadyForQuery
          pq,@pending_query = @pending_query,nil
          pq.succeed @e.size == 0, @r, @e
        when RowDescription
          @r.fields = msg.fields
        when CopyInResponse
        when CopyOutResponse
        when EmptyQueryResponse
        when ErrorResponse
          @e << msg.field_values[2]
        when NoticeResponse
          @notice_processor.call(msg) if @notice_processor
        when ParameterStatus
        else
          # TODO
          puts "Unknown Postgres message: #{msg}"
        end
      end
    end
  end
end
