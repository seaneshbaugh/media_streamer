# Media Streamer

A simple music server using Sinatra. Yarr.

Requirements
------------

#### Ruby Version

Ruby 1.9.3-p125 or higher (although, any 1.9 version should work).

#### Gems

* sinatra
* sinatra-contrib

Installation
------------

    $ git clone git@github.com:seaneshbaugh/media_streamer.git media_streamer
    $ cd media_streamer
    $ bundle install

Usage
-----

```ruby
ruby server.rb
```

This application defaults to development mode (like all Sinatra applications). To run in production mode do the following: `RAKE_ENV=production ruby server.rb`.

Example settings.yml
--------------------

Because the settings I use are guaranteed to be different from the settings you will use I've excluded my settings.yml file from the source control. Below are the settings I use:

    development:
      music_directory: "/Users/seshbaugh/Music/iTunes/iTunes Media/"
      allowed_file_types:
        - "mp3"
        - "m4a"
        - "ogg"
      default_encoding: "shift_jis"
      file_blacklist:
        - "Automatically Add to iTunes"
        - "Automatically Add to iTunes.localized"
        - "Mobile Applications"
        - "Album Artwork"

    production:
      music_directory: "J:/Music/"
      allowed_file_types:
        - "mp3"
        - "m4a"
        - "ogg"
      default_encoding: "shift_jis"
      file_blacklist:
        - "Automatically Add to iTunes"
        - "Automatically Add to iTunes.localized"
        - "Mobile Applications"
        - "Album Artwork"

You will obviously want to set the `music_directory` to wherever your music lives. In almost all cases it is best to leave out the `default_encoding` setting or set it to the more sensible "utf-8". I use "shift_jis" because I have lots of files with shift_jis encoded names. For more information about encodings visit [the W3C documentation](http://www.w3.org/TR/html5/the-meta-element.html#charset).

For a complete list of Sinatra's available settings go [here](http://www.sinatrarb.com/intro#Available%20Settings).

Currently the only settings specific to this application are `music_directory`, `allowed_file_types`, and `file_blacklist`. All three are required.

Notes
-----

* Use this at your own risk.
* You'll probably need to set up port forwarding for your router.
