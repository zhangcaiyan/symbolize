require 'rubygems'
# require 'pry'
begin
  require 'spec'
rescue LoadError
  require 'rspec'
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'i18n'
I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'locales', '*.{rb,yml}')]
I18n.default_locale = 'pt'

if ENV['CI']
  require 'coveralls'
  Coveralls.wear!
end

#
# Mongoid
#
unless ENV['ONLY_AR']

  require 'mongoid'
  puts "Using Mongoid v#{Mongoid::VERSION}"

  Mongoid.configure do |config|
    # config.master = Mongo::Connection.new.db("symbolize_test")
    config.connect_to('symbolize_test')
  end

  require 'symbolize/mongoid'

  RSpec.configure do |config|
    config.before(:each) do
      Mongoid.purge!
    end
  end
end

#
# ActiveRecord
#
unless ENV['ONLY_MONGOID']

  require 'active_record'
  require 'symbolize/active_record'

  puts "Using ActiveRecord #{ActiveRecord::VERSION::STRING}"

  ActiveRecord::Base.send :include, Symbolize::ActiveRecord # this is normally done by the railtie

  ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:') # 'postgresql', :database => 'symbolize_test', :username => 'postgres')

  if ActiveRecord::VERSION::STRING >= '3.1'
    ActiveRecord::Migrator.migrate('spec/db')
  else
    require 'db/001_create_testing_structure'
    CreateTestingStructure.migrate(:up)
  end

end
