raise LoadError, "Ruby 1.9.1 only" if RUBY_VERSION < '1.9.1'

#require '.bundle/environment'
require 'rubygems'
require 'sinatra/base'
require 'fiber'

$LOAD_PATH << File.dirname(__FILE__) + '/../lib'

require 'rails'
require 'rack/fiber_pool'
require 'active_record'
require 'active_record/connection_adapters/abstract_adapter'

class Site < ActiveRecord::Base
end

# rackup -s thin app.rb
# http://localhost:9292/test
class App < Sinatra::Base

  use Rack::FiberPool do |fp|
    ActiveRecord::ConnectionAdapters.register_fiber_pool(fp)
  end
  # ConnectionManagement must come AFTER FiberPool
  use ActiveRecord::ConnectionAdapters::ConnectionManagement

  set :root, File.dirname(__FILE__)
  set :logging, true
  set :show_exceptions, Proc.new { development? || test? }
  set :raise_errors, Proc.new { production? || staging? }

  get '/test' do
    sites = Site.all
    content_type "text/plain"
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