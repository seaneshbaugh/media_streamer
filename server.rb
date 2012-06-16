# encoding: UTF-8

require 'sinatra'
require 'cgi'

require './blank'
require './fuzzy'

#music_directory = 'J:/Music/'
music_directory = '/Users/seshbaugh/Music/iTunes/iTunes Media/'

get '/' do
  @pwd = music_directory

  @directories = get_directories(@pwd)

  add_breadcrumb(@pwd)

  erb :index
end

get '/:artist' do
  if check_blacklist(params[:artist])
    status 404
  else
    @pwd = music_directory

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
    @pwd = music_directory

    add_breadcrumb(@pwd)

    if File.exists?(File.join(@pwd, params[:artist]))
      @pwd = File.join(@pwd, params[:artist])

      add_breadcrumb(params[:artist])

      if File.exists?(File.join(@pwd, params[:album]))
        @pwd = File.join(@pwd, params[:album])

        @files = get_files(@pwd)

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
    @pwd = music_directory

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

  @pwd = music_directory

  if @request_path.length > 2 && File.exists?(File.join(@pwd, CGI::unescape(@request_path[1])))
    @pwd = File.join(@pwd, CGI::unescape(@request_path[1]))

    @artist = CGI::unescape(request_path[1])

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

  erb :'404', layout: false
end


def check_blacklist(param)
  blacklist = ['Automatically Add to iTunes', 'Automatically Add to iTunes.localized', 'Mobile Applications', 'Album Artwork']

  !blacklist.index(param).nil?
end

def get_directories(pwd)
  Dir.entries(pwd, { encoding: 'UTF-8' }).select { |entry| File.directory? File.join(pwd, entry) and !(entry == '.' || entry == '..') }.delete_if { |directory| check_blacklist(File.split(directory).last) }
end

def get_files(pwd)
  mp3_files = Dir[File.join(pwd, '*.mp3')]

  m4a_files = Dir[File.join(pwd, '*.m4a')]

  (mp3_files + m4a_files).sort
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

    erb template, { layout: false }, locals
  end
end
