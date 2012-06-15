# encoding: UTF-8

require 'sinatra'

require './blank'

music_directory = 'J:/Music/'

get '/' do
  @pwd = music_directory

  @directories = get_directories(@pwd)

  erb :index
end

get '/:artist' do
  if check_blacklist(params[:artist])
    status 404
  else
    @pwd = music_directory

    if File.exists?(File.join(@pwd, params[:artist]))
      @pwd = File.join(@pwd, params[:artist])

      @directories = get_directories(@pwd)

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

    if File.exists?(File.join(@pwd, params[:artist]))
      @pwd = File.join(@pwd, params[:artist])

      if File.exists?(File.join(@pwd, params[:album]))
        @pwd = File.join(@pwd, params[:album])

        mp3_files = Dir[File.join(@pwd, '*.mp3')]

        m4a_files = Dir[File.join(@pwd, '*.m4a')]

        @files = (mp3_files + m4a_files).sort

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

def check_blacklist(param)
  blacklist = ['Automatically Add to iTunes']

  !blacklist.index(param).nil?
end

def get_directories(pwd)
  Dir.entries(pwd, { encoding: 'UTF-8' }).select { |entry| File.directory? File.join(pwd, entry) and !(entry == '.' || entry == '..') }.delete_if { |directory| check_blacklist(File.split(directory).last) }
end

def breadcrumbs(pwd)
  directories = pwd.split(File::SEPARATOR).map { |x| x == '' ? File::SEPARATOR : x }

  directories[1] = File.join(directories[0], directories[1])

  directories.shift

  directories
end

helpers do
  def partial template, locals = nil
    locals = locals.is_a?(Hash) ? locals : { template.to_sym => locals }

    template = ('_' + template.to_s).to_sym

    erb template, { layout: false }, locals
  end
end
