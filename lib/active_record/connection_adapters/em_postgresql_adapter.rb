require 'active_record'
require 'active_record/connection_adapters/postgresql_adapter'

require 'fiber'

module EventMachine
  module Protocols
    class Postgres3
      # TODO Support various methods on PGconn used by AR.
      def exec(sql)
        fiber = Fiber.current
        query(sql).callback do |status, result, errors|
          fiber.resume([status, result, errors])
        end
        (status, result, errors) = Fiber.yield
        return PGresult.new(result) if status
        raise RuntimeError, errors.inspect
      end
    end
  end
end

if !PGconn.respond_to?(:quote_ident)
  def PGconn.quote_ident(name)
    %("#{name}")
  end
end

module ActiveRecord
  module ConnectionAdapters
    class EmPostgreSQLAdapter < PostgreSQLAdapter
      def initialize(connection, logger, host_parameters, connection_parameters, config)
        @hostname = host_parameters[0]
        @port = host_parameters[1]
        @connect_parameters, @config = connection_parameters, config
        super(connection, logger, nil, config)
      end
      
      def connect
        @logger.debug "Connecting to #{@hostname}:#{@port}"
        @connection = ::EM.connect(@hostname, @port, ::EM::P::Postgres3)
        
        fiber = Fiber.current
        @connection.connect(*@connect_parameters).callback do |result|
          fiber.resume(result)
        end
        
        raise RuntimeError, "Connection failed" if !Fiber.yield
        
        # Use escape string syntax if available. We cannot do this lazily when encountering
        # the first string, because that could then break any transactions in progress.
        # See: http://www.postgresql.org/docs/current/static/runtime-config-compatible.html
        # If PostgreSQL doesn't know the standard_conforming_strings parameter then it doesn't
        # support escape string syntax. Don't override the inherited quoted_string_prefix.
        if supports_standard_conforming_strings?
          self.class.instance_eval do
            define_method(:quoted_string_prefix) { 'E' }
          end
        end

        # Money type has a fixed precision of 10 in PostgreSQL 8.2 and below, and as of
        # PostgreSQL 8.3 it has a fixed precision of 19. PostgreSQLColumn.extract_precision
        # should know about this but can't detect it there, so deal with it here.
        money_precision = (postgresql_version >= 80300) ? 19 : 10
        PostgreSQLColumn.module_eval(<<-end_eval)
          def extract_precision(sql_type)  # def extract_precision(sql_type)
            if sql_type =~ /^money$/       #   if sql_type =~ /^money$/
              #{money_precision}           #     19
            else                           #   else
              super                        #     super
            end                            #   end
          end                              # end
        end_eval

        configure_connection
      end
      
      def active?
        # We're asking the driver, not ActiveRecord, so use @connection.query instead of #query
        @connection.exec 'SELECT 1'
        true
      rescue RuntimeError
        false
      end

    end
  end

  class Base
    # Establishes a connection to the database that's used by all Active Record objects
    def self.em_postgresql_connection(config) # :nodoc:
      config = config.symbolize_keys
      host     = config[:host]
      port     = config[:port] || 5432
      username = config[:username].to_s if config[:username]
      password = config[:password].to_s if config[:password]

      if config.has_key?(:database)
        database = config[:database]
      else
        raise ArgumentError, "No database specified. Missing argument: database."
      end

      # The postgres drivers don't allow the creation of an unconnected PGconn object,
      # so just pass a nil connection object for the time being.
      ConnectionAdapters::EmPostgreSQLAdapter.new(nil, logger, [host, port], [database, username, password], config)
    end
  end
  
end