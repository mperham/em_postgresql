# This program demonstrates that the connection pool actual works, as does the wait_timeout option.
# You need to provide your own configuration to #establish_connection.

gem "postgres-pr"
gem "em_postgresql"
require "eventmachine"
require "fiber"
require "active_record"
require "benchmark"

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection :adapter      => "em_postgresql",
                                        :port         => 5432,
                                        :pool         => 2,
                                        :username     => "cjbottaro",
                                        :host         => "localhost",
                                        :database     => "test",
                                        :wait_timeout => 2

EM.run do
  Fiber.new do
    fibers = []
    time = Benchmark.realtime do

      fibers = 5.times.collect do
        Fiber.new do
          begin
            ActiveRecord::Base.connection.execute "select pg_sleep(1)"
            ActiveRecord::Base.clear_active_connections!
          rescue => e
            puts e.inspect
          end
        end.tap{ |fiber| fiber.resume }
      end

      fibers.each do |fiber|
        while fiber.alive?
          current_fiber = Fiber.current
          EM.next_tick{ current_fiber.resume }
          Fiber.yield
        end
      end

      puts "first batch done"

      # This is a copy/paste job.
      fibers = 5.times.collect do
        Fiber.new do
          begin
            ActiveRecord::Base.connection.execute "select pg_sleep(1)"
            ActiveRecord::Base.clear_active_connections!
          rescue => e
            puts e.inspect
          end
        end.tap{ |fiber| fiber.resume }
      end

      fibers.each do |fiber|
        while fiber.alive?
          current_fiber = Fiber.current
          EM.next_tick{ current_fiber.resume }
          Fiber.yield
        end
      end

    end
    puts time
    EM.stop
  end.resume
end
