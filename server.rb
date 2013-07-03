class MediaStreamer < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  configure :development, :production do
    enable :logging

    file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')

    file.sync = true

    use Rack::CommonLogger, file
  end

  register Sinatra::ConfigFile

  config_file 'config/settings.yml'

  helpers Sinatra::JSON

  get '/' do
    @pwd = settings.music_directory

    @directories = get_directories(@pwd)

    add_breadcrumb(@pwd)

    erb :index
  end

  get '/api/v1/?' do
    @pwd = settings.music_directory

    @directories = get_directories(@pwd)

    json :artists => @directories.map { |artist| { :name => artist, :url => "#{base_url}#{artist}", :api_url => "#{base_url}/api/v1/#{artist}" } }
  end

  get '/api/v1/:artist/?' do
    if check_blacklist(params[:artist])
      status 404
    else
      @pwd = settings.music_directory

      if File.exists?(File.join(@pwd, params[:artist]))
        @pwd = File.join(@pwd, params[:artist])

        @directories = get_directories(@pwd)

        json :albums => @directories.map { |album| { :name => album, :url => "#{base_url}/#{params[:artist]}/#{album}", :api_url => "#{base_url}/api/v1/#{params[:artist]}/#{album}" } }
      else
        status 404
      end
    end
  end

  get '/api/v1/:artist/:album/?' do
    if check_blacklist(params[:artist]) || check_blacklist(params[:album])
      status 404
    else
      @pwd = settings.music_directory

      if File.exists?(File.join(@pwd, params[:artist]))
        @pwd = File.join(@pwd, params[:artist])

        if File.exists?(File.join(@pwd, params[:album]))
          @pwd = File.join(@pwd, params[:album])

          @files = get_files(@pwd)

          json :songs => @files.map { |file| file.split('/').last }.map { |song| { :name => song, :url => "#{base_url}/#{params[:artist]}/#{params[:album]}/#{song}" } }
        else
          status 404
        end
      else
        status 404
      end
    end
  end

  get '/:artist/?' do
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

  get '/:artist/:album/?' do
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

  helpers do
    def partial(template, locals = nil)
      locals = locals.is_a?(Hash) ? locals : { template.to_sym => locals }

      template = ('_' + template.to_s).to_sym

      erb template, { :layout => false }, locals
    end

    def base_url
      @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
    end
  end

  run! if app_file == $0

  protected

  def check_blacklist(directory_or_file_name)
    !settings.file_blacklist.index(directory_or_file_name).nil?
  end

  def get_directories(pwd)
    Dir.entries(pwd, { :encoding => 'UTF-8' }).select { |entry| File.directory?(File.join(pwd, entry)) && !(entry == '.' || entry == '..') }.delete_if { |directory| check_blacklist(directory.split('/').last) }
  end

  def get_files(pwd)
    files = []

    settings.allowed_file_types.each do |file_type|
      files += Dir[File.join(pwd, "*.#{file_type}")]
    end

    files.delete_if { |file| check_blacklist(file) }.sort
  end

  def add_breadcrumb(breadcrumb)
    @breadcrumbs ||= []

    if breadcrumb.present?
      @breadcrumbs << breadcrumb
    end

    @breadcrumbs
  end
end
