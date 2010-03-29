raise LoadError, "Ruby 1.9.1 only" if RUBY_VERSION < '1.9.1'

#require '.bundle/environment'
require 'rubygems'
require 'sinatra/base'
require 'sinatra/async'
require 'fiber'

$LOAD_PATH << File.dirname(__FILE__) + '/../lib'

require 'rails'
require 'rack/fiber_pool'

class Site < ActiveRecord::Base
end

# rackup -s thin app.rb
# http://localhost:9292/test
class App < Sinatra::Base
  register Sinatra::Async

  use Rack::FiberPool do |fp|
    fp.generic_callbacks << lambda {
      ActiveRecord::Base.clear_active_connections!
    }
    ActiveRecord::ConnectionAdapters.register_fiber_pool(fp)
  end

  set :root, File.dirname(__FILE__)
  set :logging, true
  set :show_exceptions, Proc.new { development? || test? }
  set :raise_errors, Proc.new { production? || staging? }
  
  get '/test' do
    sites = Site.all
    content_type "text/javascript"
    body sites.inspect
  end

  helpers do
    def self.staging?
      environment == :staging
    end
  end
  
  configure do
    Rails.bootstrap
  end

end