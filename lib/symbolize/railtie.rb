# Rails 3 initialization
module Symbolize
  if defined? ActiveRecord
    require 'rails'
    require 'symbolize/active_record'
    class Railtie < Rails::Railtie
      initializer 'symbolize.insert_into_active_record' do
        ActiveSupport.on_load :active_record do
          ActiveRecord::Base.send :include, Symbolize::ActiveRecord
        end
      end
    end
  end
end
