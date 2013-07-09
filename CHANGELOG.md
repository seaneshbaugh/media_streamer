## v0.5.1
#### 2013/07/09

* Cleaned up check_blacklist to allow an arbitrary number of parameters.
* Fixed bug in call to check_blacklist in get_files.

## v0.5.0
#### 2013/07/09

* Added support for reading media tags ([tag-lib](http://taglib.github.io/) now required).
* Added album art.
* Refactored a bunch of stuff.
* Major updates to API. Kept at v1 because nothing is using it yet.
* Now using File.directory? and File.file? instead of File.exists?.

## v0.4.0
#### 2013/07/04

* Added HTML5 audio player.
* Updated readme.

## v0.3.0
#### 2013/07/03

* Changed to modular Sinatra app.
* Removed .rvmrc and replaced with .ruby-version and .ruby-gemset.
* Bumped Ruby version to 2.0.0-p247.
* Added active_support dependency since it's just easier that way.
* Updated readme.
* Added blacklist check to get_files.
* Artist, album, and API routes now respond to optional trailing slash.
* Added base_url helper method.
* Added URL and API URL to API results.
* Added favicon.
* Added empty JavaScript file for later.
* Added empty CSS file for later.

## v0.2.1
#### 2012/09/03

* Now using sinatra-contrib.
* Settings now load using sinatra/config_file.
* Added JSON API with sinatra/json.

## v0.2.0
#### 2012/09/03

* Added settings file.
* Music directory moved to settings.
* File blacklist moved to settings.
* Allowed file types moved to settings.
* Added character encoding to settings.
* Added command line option for listen port.
* Now using "directory.split('/').last" because it's more clear in its intent.
* Reverted to 1.8 style Hash rockets because I think they're more clear in their intent.

## v0.1.4
#### 2012/06/15

* Simplified and fixed breadcrumbs when music_directory is a path with more than one directory.

## v0.1.3
#### 2012/06/15

* Added 404 page with suggestion.

## v0.1.2
#### 2012/06/15

* Added gemfile and changelog.
* Fixed tabs to be double spaces.
* Now uses Ruby 1.9 hash syntax.

## v0.1.1
#### 2012/06/14

* Finally got around to putting this under source control.
* Added readme and rvmrc.

## v0.1.0
#### 2012/06/13

* File/Directory names are now served as UTF-8 instead of ASCII-8BIT.
* Now requires Ruby 1.9.3p125 or higher (although, any 1.9 version should work).

## v0.0.2
#### 2012/06/12

* Navigation breadcrumbs added.
* File/Directory blacklist added.
* Changes to behavior of how directories are found.

## v0.0.1
#### 2012/06/11

* Initial release.
