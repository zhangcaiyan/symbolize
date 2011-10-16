require 'rubygems'
begin
  require 'spec'
rescue LoadError
  require 'rspec'
end
require 'pry'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'i18n'


I18n.load_path += Dir[File.join(File.dirname(__FILE__), "locales", "*.{rb,yml}")]
I18n.default_locale = "pt"

