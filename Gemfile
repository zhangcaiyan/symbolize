source "https://rubygems.org"
gemspec

gem "rake"

group :test do
  gem 'rspec'
  gem 'bson_ext'
  gem 'mongoid'
  gem 'pg'
  gem 'i18n' #, '0.6.1'
  gem 'sqlite3'
  gem 'activesupport', '3.2.13'
  gem 'activerecord', '3.2.13'
  gem 'activemodel', '3.2.13'

  if ENV["CI"]
    gem "coveralls", require: false
  end

end
