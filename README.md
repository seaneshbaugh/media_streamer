# Media Streamer

A simple music server using Sinatra. Yarr.

Requirements
------------

#### Ruby Version
Ruby 2.0.0-p247 or higher (although, any 1.9.3 or 2.0.0 version should work).

#### Gems
* activesupport
* sinatra
* sinatra-contrib
* thin

Installation
------------

    $ git clone git@github.com:seaneshbaugh/media_streamer.git media_streamer
    $ cd media_streamer
    $ bundle install

Usage
-----

```ruby
rackup
```

This application defaults to development mode (like all Sinatra applications). To run in production mode do the following:

```ruby
RAKE_ENV=production rackup
```

To run on a different port:

```ruby
rackup -p 9999
```

Example settings.yml
--------------------

Because the settings I use are guaranteed to be different from the settings you will use I've excluded my settings.yml file from source control. Below are some sample settings:

    development:
      music_directory: "/Users/me/Music/"
      allowed_file_types:
        - "mp3"
        - "m4a"
        - "ogg"
      default_encoding: "utf-8"
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
      default_encoding: "utf-8"
      file_blacklist:
        - "Automatically Add to iTunes"
        - "Automatically Add to iTunes.localized"
        - "Mobile Applications"
        - "Album Artwork"
      protection:
        except: :json_csrf

You will obviously want to set the `music_directory` to wherever your music lives.

For a complete list of Sinatra's available settings go [here](http://www.sinatrarb.com/intro#Available%20Settings).

Currently the only settings specific to this application are `music_directory`, `allowed_file_types`, and `file_blacklist`. All three are required.

Notes
-----

* Use this at your own risk.
* You'll probably need to set up port forwarding for your router.
* It is highly recommended you keep the robots.txt file in place.
