# vim: syntax=Ruby
require 'rubygems'
# require 'rake/testtask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "em_postgresql"
    s.summary = s.description = "An ActiveRecord driver for using Postgresql with EventMachine"
    s.email = "mperham@gmail.com"
    s.homepage = "http://github.com/mperham/em_postgresql"
    s.authors = ['Mike Perham']
    s.files = FileList["[A-Z]*", "{lib,test}/**/*"]
    s.test_files = FileList["test/test_*.rb"]
  end

rescue LoadError
  puts "Jeweler not available. Install it for jeweler-related tasks with: sudo gem install jeweler"
end


# Rake::TestTask.new do |t|
#   t.warning = true
# end

# TODO Figure out how to integrate EM with test/unit.
task :test do
  $LOAD_PATH << File.expand_path('lib')
  $LOAD_PATH << File.expand_path('test')
  require 'test_database'
end

task :default => :test