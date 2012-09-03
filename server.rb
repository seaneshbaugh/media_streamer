# encoding: UTF-8

require 'optparse'
require 'yaml'
require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/json'
require 'json'
require 'cgi'

Dir["#{File.dirname(__FILE__)}/lib/*.rb"].sort.each do |path|
  require path
end

set :json_encoder, :to_json

config_file 'config/settings.yml'

OptionParser.new do |opts|
  opts.on('-p', '--port [PORT]', 'Listen on the specified port.') do |port|
    set :port, port
  end
end.parse!

get '/' do
  @pwd = settings.music_directory

  @directories = get_directories(@pwd)

  add_breadcrumb(@pwd)

  erb :index
end

get '/api/v1/' do
  @pwd = settings.music_directory

  @directories = get_directories(@pwd)

  json :artists => @directories
end

get '/api/v1/:artist' do
  if check_blacklist(params[:artist])
    status 404
  else
    @pwd = settings.music_directory

    if File.exists?(File.join(@pwd, params[:artist]))
      @pwd = File.join(@pwd, params[:artist])

      @directories = get_directories(@pwd)

      json :albums => @directories
    else
      status 404
    end
  end
end

get '/api/v1/:artist/:album' do
  if check_blacklist(params[:artist]) || check_blacklist(params[:album])
    status 404
  else
    @pwd = settings.music_directory

    if File.exists?(File.join(@pwd, params[:artist]))
      @pwd = File.join(@pwd, params[:artist])

      if File.exists?(File.join(@pwd, params[:album]))
        @pwd = File.join(@pwd, params[:album])

        @files = get_files(@pwd).delete_if { |song| check_blacklist(song) }

        json :songs => @files.map { |file| file.split('/').last }
      else
        status 404
      end
    else
      status 404
    end
  end
end

get '/:artist' do
  if check_blacklist(params[:artist])
    status 404
  else
    @pwd = settings.music_directory

    add_breadcrumb(@pwd)

    if File.exists?(File.join(@pwd, params[:artist]))
      @pwd = File.join(@pwd, params[:artist])

      @directories = get_directories(@pwd)

      add_breadcrumb(params[:artist])

      erb :artist
    else
      status 404
    end
  end
end

get '/:artist/:album' do
  if check_blacklist(params[:artist]) || check_blacklist(params[:album])
    status 404
  else
    @pwd = settings.music_directory

    add_breadcrumb(@pwd)

    if File.exists?(File.join(@pwd, params[:artist]))
      @pwd = File.join(@pwd, params[:artist])

      add_breadcrumb(params[:artist])

      if File.exists?(File.join(@pwd, params[:album]))
        @pwd = File.join(@pwd, params[:album])

        @files = get_files(@pwd).delete_if { |song| check_blacklist(song) }

        add_breadcrumb(params[:album])

        erb :album
      else
        status 404
      end
    else
      status 404
    end
  end
end

get '/:artist/:album/:song' do
  if check_blacklist(params[:artist]) || check_blacklist(params[:album]) || check_blacklist(params[:song])
    status 404
  else
    @pwd = settings.music_directory

    if File.exists?(File.join(@pwd, params[:artist]))
      @pwd = File.join(@pwd, params[:artist])

      if File.exists?(File.join(@pwd, params[:album]))
        @pwd = File.join(@pwd, params[:album])

        if File.exists?(File.join(@pwd, params[:song]))
          send_file File.join(@pwd, params[:song])
        else
          status 404
        end
      else
        status 404
      end
    else
      status 404
    end
  end
end

not_found do
  @request_path = request.env['REQUEST_PATH'].split('/')

  @pwd = settings.music_directory

  if @request_path.length > 2 && File.exists?(File.join(@pwd, CGI::unescape(@request_path[1])))
    @pwd = File.join(@pwd, CGI::unescape(@request_path[1]))

    @artist = CGI::unescape(@request_path[1])

    if @request_path.length > 3 && File.exists?(File.join(@pwd, CGI::unescape(@request_path[2])))
      @pwd = File.join(@pwd, CGI::unescape(@request_path[2]))

      @album = CGI::unescape(@request_path[2])
    end
  end

  if @album.blank?
    @closest = FuzzyMatch::find_closest_match CGI::unescape(@request_path.last), get_directories(@pwd)
  else
    @files = get_files(@pwd)

    @files.each { |file| file.slice! "#{@pwd}/" }

    @closest = FuzzyMatch::find_closest_match CGI::unescape(@request_path.last), @files
  end

  erb :'404', :layout => false
end

def check_blacklist(param)
  !settings.file_blacklist.index(param).nil?
end

def get_directories(pwd)
  Dir.entries(pwd, { :encoding => 'UTF-8' }).select { |entry| File.directory? File.join(pwd, entry) and !(entry == '.' || entry == '..') }.delete_if { |directory| check_blacklist(directory.split('/').last) }
end

def get_files(pwd)
  files = []

  settings.allowed_file_types.each do |file_type|
    files += Dir[File.join(pwd, "*.#{file_type}")]
  end

  files.sort
end

def add_breadcrumb breadcrumb
  @breadcrumbs ||= []

  if breadcrumb.present?
    @breadcrumbs << breadcrumb
  end

  @breadcrumbs
end

helpers do
  def partial template, locals = nil
    locals = locals.is_a?(Hash) ? locals : { template.to_sym => locals }

    template = ('_' + template.to_s).to_sym

    erb template, { :layout => false }, locals
  end
end
