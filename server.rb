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

    read_genre_cache

    erb :index
  end

  get '/api/v1/?' do
    @pwd = settings.music_directory

    @directories = get_directories(@pwd)

    read_genre_cache

    artists = @directories.map do |artist|
      {
        name: artist,
        genre: @genres[artist.split('/').last] || nil,
        url: "#{base_url}/#{artist}",
        api_url: "#{base_url}/api/v1/#{artist}"
      }
    end

    content_type :json

    if params[:p] || params[:pretty]
      JSON.pretty_generate(artists: artists)
    else
      { artists: artists }.to_json
    end
  end

  get '/api/v1/:artist/?' do
    @artist = params[:artist]

    if check_blacklist(@artist)
      status 404
    else
      @pwd = File.join(settings.music_directory, @artist)

      if File.directory?(@pwd)
        @directories = get_directories(@pwd)

        artist_name = nil

        albums = @directories.map do |album|
          first_file = get_files(File.join(settings.music_directory, @artist, album)).first

          first_file_tag = get_tags(first_file)

          artist_name = first_file_tag[:artist] unless artist_name

          {
            name: first_file_tag[:album],
            url: "#{base_url}/#{@artist}/#{album}",
            api_url: "#{base_url}/api/v1/#{@artist}/#{album}"
          }
        end

        artist = {
          name: artist_name,
          url: "#{base_url}/#{@artist}",
          albums: albums
        }

        content_type :json

        if params[:p] || params[:pretty]
          JSON.pretty_generate(artist: artist)
        else
          { artist: artist }.to_json
        end
      else
        status 404
      end
    end
  end

  get '/api/v1/:artist/:album/?' do
    @artist = params[:artist]

    @album = params[:album]

    if check_blacklist(@artist, @album)
      status 404
    else
      @pwd = File.join(settings.music_directory, @artist, @album)

      if File.directory?(@pwd)
        @files = get_files(@pwd)

        songs = @files.map do |file|
          file_name = file.split('/').last

          get_tags(file).merge(url: "#{base_url}/#{@artist}/#{@album}/#{file_name}", api_url: "#{base_url}/api/v1/#{@artist}/#{@album}/#{file_name}")
        end

        album = {
          artist: songs.first[:artist],
          title: songs.first[:album],
          url: "#{base_url}/#{@artist}/#{@album}",
          albumart: "#{base_url}/#{@artist}/#{@album}/albumart",
          songs: songs
        }

        content_type :json

        if params[:p] || params[:pretty]
          JSON.pretty_generate(album: album)
        else
          { album: album }.to_json
        end
      else
        status 404
      end
    end
  end

  get '/api/v1/:artist/:album/:song' do
    @artist = params[:artist]

    @album = params[:album]

    @song = params[:song]

    if check_blacklist(@artist, @album, @song)
      status 404
    else
      @file_path = File.join(settings.music_directory, @artist, @album, @song)

      if File.file?(@file_path)
        song = get_tags(@file_path).merge(url: "#{base_url}/#{@artist}/#{@album}/#{@song}")

        content_type :json

        if params[:p] || params[:pretty]
          JSON.pretty_generate(song: song)
        else
          { song: song }.to_json
        end
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

    if check_blacklist(@artist, @album)
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

    if check_blacklist(@artist, @album)
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

    if check_blacklist(@artist, @album, @song)
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

    def make_path(*parts)
      "/#{parts.join('/')}".gsub('#', '%23')
    end
  end

  run! if app_file == $0

  protected

  def check_blacklist(*directory_or_file_names)
    (settings.file_blacklist & directory_or_file_names.flatten).length != 0
  end

  def get_directories(pwd)
    Dir.entries(pwd, { :encoding => 'UTF-8' }).select { |entry| File.directory?(File.join(pwd, entry)) && !(entry == '.' || entry == '..') }.delete_if { |directory| check_blacklist(directory.split('/').last) }
  end

  def get_files(pwd)
    files = []

    settings.allowed_file_types.each do |file_type|
      files += Dir[File.join(pwd, "*.#{file_type}")]
    end

    files.delete_if { |file| check_blacklist(file.split('/').last) }.sort
  end

  def add_breadcrumb(breadcrumb)
    @breadcrumbs ||= []

    if breadcrumb.present?
      @breadcrumbs << breadcrumb
    end

    @breadcrumbs
  end

  def read_genre_cache
    genre_cache_file_path = File.join('tmp', 'genres.txt')

    if File.file?(genre_cache_file_path)
      lines = File.readlines(genre_cache_file_path, encoding: 'UTF-8').reject(&:empty?)

      puts lines.length
      puts @directories.length

      if lines.length == @directories.length
        @genres = {}

        lines.each do |line|
          artist, genre = line.split(' -:-:- ')

          @genres[artist] = genre.present? ? genre.chomp : 'Unknown'
        end
      else
        # lines.each do |line|
        #   artist, genre = line.split(' -:-:- ')
        #
        #   unless @directories.include?(artist)
        #     puts "#{artist} is missing!"
        #   end
        # end
        #
        # artists = lines.map { |line| line.split(' -:-:- ').first }
        #
        # @directories.each do |directory|
        #   unless artists.include?(directory)
        #     puts "#{directory} is missing!"
        #   end
        # end

        cache_genres(genre_cache_file_path)
      end
    else
      cache_genres(genre_cache_file_path)
    end
  end

  def cache_genres(genre_cache_file_path)
    directory, filename = File.split(genre_cache_file_path)

    File.open(File.join(FileUtils.mkdir_p(directory).first, filename), 'w+') do |genre_cache_file|
      genres = {}

      @directories.each do |artist|
        puts artist

        album = get_directories(File.join(settings.music_directory, artist)).first

        if album
          puts album

          first_song = get_files(File.join(settings.music_directory, artist, album)).first

          if first_song
            puts first_song

            TagLib::FileRef.open(first_song) do |file|
              unless file.null?
                tag = file.tag

                puts tag.genre

                genres[artist] = tag.genre

                genre_cache_file.puts "#{artist} -:-:- #{tag.genre}"
              end
            end
          else
            genre_cache_file.puts "#{artist} -:-:- Unknown"
          end
        else
          genre_cache_file.puts "#{artist} -:-:- Unknown"
        end
      end

      @genres = genres
    end
  end

  def get_tags(file_path)
    return {} unless File.file?(file_path)

    return {} unless file_path.split('.').last.downcase == 'mp3'

    song = {}

    TagLib::MPEG::File.open(file_path) do |file|
      unless file.nil?
        tag = file.id3v2_tag

        tag.frame_list.each do |frame|
          frame_id = translate_id3_frame_id(frame.frame_id)

          song[frame_id] = frame.to_string if frame_id
        end

        song[:audio_properties] = {
          bitrate: file.audio_properties.bitrate,
          channels: file.audio_properties.channels,
          length: file.audio_properties.length,
          sample_rate: file.audio_properties.sample_rate,
        }
      end
    end

    song
  end

  def translate_id3_frame_id(frame_id)
    frame_ids = {
      'TIT2' => :title,
      'TALB' => :album,
      'TDRC' => :year,
      'TPE1' => :artist,
      'TRCK' => :track,
      'TPOS' => :disc,
      'COMM' => :comment,
      'TCON' => :genre
    }

    frame_ids[frame_id]
  end
end
