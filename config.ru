# frozen_string_literal: true

require 'bundler/setup'

Bundler.require(:default)

require 'sinatra/config_file'
require 'sinatra/reloader'
require 'sinatra/json'
require 'cgi'

Dir[File.join('.', 'lib', '*.rb')].sort.each do |path|
  require_relative path
end

require_relative './server'

run MediaStreamer
