# vim: syntax=Ruby
require 'rubygems'
require 'rake/testtask'

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
    s.add_dependency 'postgres-pr', '>=0.6.1'
    s.add_dependency 'eventmachine', '>=0.12.10'
  end

rescue LoadError
  puts "Jeweler not available. Install it for jeweler-related tasks with: sudo gem install jeweler"
end


task :gin => [:gemspec, :build] do
	puts `gem install pkg/em_postgresql-#{File.read('VERSION').strip}.gem`
end


Rake::TestTask.new

task :default => :test
