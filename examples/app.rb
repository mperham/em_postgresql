raise LoadError, "Ruby 1.9.1 only" if RUBY_VERSION < '1.9.1'

#require '.bundle/environment'
require 'rubygems'
require 'sinatra/base'
require 'sinatra/async'
require 'fiber'

$LOAD_PATH << File.dirname(__FILE__) + '/../lib'

require 'rails'
require 'fiber_pool'

class Site < ActiveRecord::Base
end

# rackup -s thin app.rb
# http://localhost:9292/test
class App < Sinatra::Base
  register Sinatra::Async
  
  set :root, File.dirname(__FILE__)
  set :logging, true
  set :show_exceptions, Proc.new { development? || test? }
  set :raise_errors, Proc.new { production? || staging? }
  
  aget '/test' do
    fiber do
      sites = Site.all
      content_type "text/javascript"
      body sites.inspect
    end
  end

  helpers do
    def fiber(&block)
      FIBER_POOL.spawn do
        begin
          yield
        ensure
          ActiveRecord::Base.clear_active_connections!
        end
      end
    end

    def self.staging?
      environment == :staging
    end
  end
  
  configure do
    Rails.bootstrap
    FIBER_POOL = FiberPool.new
    ::ActiveRecord::ConnectionAdapters::EmPostgreSQLAdapter::FIBERS = FIBER_POOL
  end

end