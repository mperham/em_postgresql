require 'active_record'
require 'erb'

Time.zone = 'UTC'

module ::Rails
  def self.bootstrap
    Rails.logger.info "Bootstrapping Rails [#{Rails.root}, #{Rails.env}]"

    Object.const_set(:RAILS_ENV, Rails.env.to_s)
    Object.const_set(:RAILS_ROOT, Rails.root)

    filename = File.join(Rails.root, 'config', 'database.yml')
    ActiveRecord::Base.configurations = YAML::load(ERB.new(File.read(filename)).result)
    ActiveRecord::Base.default_timezone = :utc
    ActiveRecord::Base.logger = Rails.logger
    ActiveRecord::Base.time_zone_aware_attributes = true
    ActiveRecord::Base.establish_connection
  end
  def self.root
    ::App.root
  end
  def self.env
    ::App.environment
  end
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end


