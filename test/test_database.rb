require 'rubygems'
require 'logger'
require 'yaml'
require 'erb'

gem 'activerecord', '>= 2.3.5'
require 'active_record'

RAILS_ENV='test'

ActiveRecord::Base.configurations = YAML::load(ERB.new(File.read(File.join(File.dirname(__FILE__), 'database.yml'))).result)
ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = Logger::INFO
ActiveRecord::Base.pluralize_table_names = false
ActiveRecord::Base.time_zone_aware_attributes = true
Time.zone = 'UTC'

require 'eventmachine'
require 'test/unit'

class Site < ActiveRecord::Base
  set_table_name 'site'
end

class TestDatabase < Test::Unit::TestCase
  def test_live_server
    EM.run do
      Fiber.new do
        ActiveRecord::Base.establish_connection

        result = ActiveRecord::Base.connection.query('select id, domain_name from site')
        assert result
        assert_equal 3, result.size

        result = Site.all
        assert result
        assert_equal 3, result.size

        result = Site.find(1)
        assert_equal 1, result.id
        assert_equal 'somedomain.com', result.domain_name
      end.resume

      EM.add_timer(1) do
        EM.stop
      end

    end
  end
end