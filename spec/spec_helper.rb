require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/features/'
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'conjur-policy-parser'
require 'logger'

if ENV['DEBUG']
  Conjur::Policy::YAML::Handler.logger.level = Logger::DEBUG 
end

