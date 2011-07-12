require 'rubygems'
begin
  require 'spec'
rescue LoadError
  require 'rspec'
end
require 'pry'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'active_record'
require 'action_controller'
require 'action_view'
require 'symbolize'
require File.join(File.dirname(__FILE__), '..', 'init')
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:") #'postgresql', :database => 'symbolize_test', :username => 'postgres')

if ActiveRecord::VERSION::STRING >= "3.1"
  ActiveRecord::Migrator.migrate("spec/db")
else
  require "db/001_create_testing_structure"
  CreateTestingStructure.migrate(:up)
end

I18n.load_path += Dir[File.join(File.dirname(__FILE__), "locales", "*.{rb,yml}")]
I18n.default_locale = "pt"

puts "Running AR #{ActiveRecord::VERSION::STRING}"
# Spec::Runner.configure do |config|
# end
