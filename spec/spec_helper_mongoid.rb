require File.dirname(__FILE__) + '/spec_helper'
require 'mongoid'
require 'mongoid/version'

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db("symbolize_test")
end

Mongoid.database.collections.each do |collection|
  unless collection.name =~ /^system\./
    collection.remove
  end
end

puts "Running Mongoid #{Mongoid::VERSION}"

require 'symbolize/mongoid'
