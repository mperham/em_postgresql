require 'fiber_pool'

module Rack
  # Runs each request in a Fiber.  Optionally can limit the
  # Fibers to a given pool.
  class FiberPool
    VERSION = '0.8.0'
    
    def initialize(app)
      @app = app
      @fiber_pool = ::FiberPool.new
      yield @fiber_pool if block_given?
    end

    def call(env)
      call_app = lambda do
        result = @app.call(env)
        env['async.callback'].call result
      end
      
      @fiber_pool.spawn(&call_app)
      throw :async
    end
  end
end