require File.dirname(__FILE__) + '/spec_helper'
require 'mongoid'
require 'mongoid/version'

Mongoid.configure do |config|
  #config.master = Mongo::Connection.new.db("symbolize_test")
  config.connect_to('symbolize_test')
end

puts "Running Mongoid #{Mongoid::VERSION}"

require 'symbolize/mongoid'

RSpec.configure do |config|
  config.before(:each) do
    Mongoid.purge!
  end
end
