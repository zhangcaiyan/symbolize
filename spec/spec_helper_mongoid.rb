require File.dirname(__FILE__) + '/spec_helper'
require 'mongoid'

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db("symbolize_#{Time.now.to_i}")
end

require 'symbolize/mongoid'
require 'support/mongoid_models'
