require 'bundler/setup'

Bundler.require(:default)

require 'sinatra/config_file'
require 'sinatra/reloader'
require 'sinatra/json'
require 'cgi'

Dir["#{File.dirname(__FILE__)}/lib/*.rb"].sort.each do |path|
  require path
end

require File.join(File.dirname(__FILE__), 'server')

run MediaStreamer
