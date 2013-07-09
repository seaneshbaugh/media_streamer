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

    add_breadcrumb(@pwd)

    @directories = get_directories(@pwd)

    erb :index
  end

  get '/api/v1/?' do
    @pwd = settings.music_directory

    @directories = get_directories(@pwd)

    json :artists => @directories.map { |artist| { :name => artist, :url => "#{base_url}#{artist}", :api_url => "#{base_url}/api/v1/#{artist}" } }
  end

  get '/api/v1/:artist/?' do
    @artist = params[:artist]

    if check_blacklist(@artist)
      status 404
    else
      @pwd = File.join(settings.music_directory, @artist)

      if File.directory?(@pwd)
        @directories = get_directories(@pwd)

        json :artist => { :name => @artist, :url => "#{base_url}/#{@artist}", :albums => @directories.map { |album| { :name => album, :url => "#{base_url}/#{@artist}/#{album}", :api_url => "#{base_url}/api/v1/#{@artist}/#{album}" } } }
      else
        status 404
      end
    end
  end

  get '/api/v1/:artist/:album/?' do
    @artist = params[:artist]

    @album = params[:album]

    if check_blacklist(@artist) || check_blacklist(@album)
      status 404
    else
      @pwd = File.join(settings.music_directory, @artist, @album)

      if File.directory?(@pwd)
        @files = get_files(@pwd)

        json :album => { :artist => @artist, :title => @album, :url => "#{base_url}/#{@artist}/#{@album}", :albumart => "#{base_url}/#{@artist}/#{@album}/albumart", :songs => @files.map { |file| file.split('/').last }.map { |song| { :name => song, :url => "#{base_url}/#{@artist}/#{@album}/#{song}", :api_url => "#{base_url}/api/v1/#{@artist}/#{@album}/#{song}" } } }
      else
        status 404
      end
    end
  end

  get '/api/v1/:artist/:album/:song' do
    @artist = params[:artist]

    @album = params[:album]

    @song = params[:song]

    if check_blacklist(@artist) || check_blacklist(@album) || check_blacklist(@song)
      status 404
    else
      @file_path = File.join(settings.music_directory, @artist, @album, @song)

      if File.file?(@file_path)
        song = {}

        TagLib::FileRef.open(@file_path) do |file|
          unless file.null?
            tag = file.tag

            song[:album] = tag.album

            song[:artist] = tag.artist

            song[:comment] = tag.comment

            song[:genre] = tag.genre

            song[:title] = tag.title

            song[:track] = tag.track

            song[:year] = tag.year

            song[:url] = "#{base_url}/#{@artist}/#{@album}/#{@song}"

            song[:audio_properties] = {}

            song[:audio_properties][:bitrate] = file.audio_properties.bitrate

            song[:audio_properties][:channels] = file.audio_properties.channels

            song[:audio_properties][:length] = file.audio_properties.length

            song[:audio_properties][:sample_rate] = file.audio_properties.sample_rate
          end
        end

        json :song => song
      else
        status 404
      end
    end
  end

  get '/:artist/?' do
    @artist = params[:artist]

    if check_blacklist(@artist)
      status 404
    else
      @pwd = settings.music_directory

      add_breadcrumb(@pwd)

      @pwd = File.join(@pwd, @artist)

      if File.directory?(@pwd)
        @directories = get_directories(@pwd)

        add_breadcrumb(@artist)

        erb :artist
      else
        status 404
      end
    end
  end

  get '/:artist/:album/albumart' do
    @artist = params[:artist]

    @album = params[:album]

    if check_blacklist(@artist) || check_blacklist(@album)
      status 404
    else
      @pwd = File.join(settings.music_directory, @artist, @album)

      if File.directory?(@pwd)
        @files = get_files(@pwd)

        if @files.present?
          case @files.first.split('.').last
            when 'mp3'
              TagLib::MPEG::File.open(@files.first) do |file|
                tag = file.id3v2_tag

                cover = tag.frame_list('APIC').first

                if cover
                  content_type cover.mime_type

                  cover.picture
                else
                  send_file File.expand_path('images/no-album-art.jpg', settings.public_folder)
                end
              end
            when 'm4a'
              #TODO: Get album art for M4A files.
              send_file File.expand_path('images/no-album-art.jpg', settings.public_folder)
            when 'ogg'
              #TODO: Get album art for OGG files.
              send_file File.expand_path('images/no-album-art.jpg', settings.public_folder)
            else
              send_file File.expand_path('images/no-album-art.jpg', settings.public_folder)
          end
        end
      else
        status 404
      end
    end
  end

  get '/:artist/:album/?' do
    @artist = params[:artist]

    @album = params[:album]

    if check_blacklist(@artist) || check_blacklist(@album)
      status 404
    else
      @pwd = File.join(settings.music_directory, @artist, @album)

      if File.directory?(@pwd)
        add_breadcrumb(settings.music_directory)

        add_breadcrumb(@artist)

        add_breadcrumb(@album)

        @files = get_files(@pwd)

        erb :album
      else
        status 404
      end
    end
  end

  get '/:artist/:album/:song' do
    @artist = params[:artist]

    @album = params[:album]

    @song = params[:song]

    if check_blacklist(@artist) || check_blacklist(@album) || check_blacklist(@song)
      status 404
    else
      @file_path = File.join(settings.music_directory, @artist, @album, @song)

      if File.file?(@file_path)
        send_file @file_path
      else
        status 404
      end
    end
  end

  not_found do
    @artist = @album = @song = nil

    @request_path = request.env['REQUEST_PATH'].split('/')

    @pwd = settings.music_directory

    if @request_path.length > 2 && File.directory?(File.join(@pwd, CGI::unescape(@request_path[1])))
      @pwd = File.join(@pwd, CGI::unescape(@request_path[1]))

      @artist = CGI::unescape(@request_path[1])

      if @request_path.length > 3 && File.directory?(File.join(@pwd, CGI::unescape(@request_path[2])))
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
