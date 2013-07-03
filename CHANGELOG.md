## v0.3.0
#### 07-03-13

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
#### 09-03-12

* Now using sinatra-contrib.
* Settings now load using sinatra/config_file.
* Added JSON API with sinatra/json.

## v0.2.0
#### 09-03-12

* Added settings file.
* Music directory moved to settings.
* File blacklist moved to settings.
* Allowed file types moved to settings.
* Added character encoding to settings.
* Added command line option for listen port.
* Now using "directory.split('/').last" because it's more clear in its intent.
* Reverted to 1.8 style Hash rockets because I think they're more clear in their intent.

## v0.1.4
#### 06-15-12

* Simplified and fixed breadcrumbs when music_directory is a path with more than one directory.

## v0.1.3
#### 06-15-12

* Added 404 page with suggestion.

## v0.1.2
#### 06-15-12

* Added gemfile and changelog.
* Fixed tabs to be double spaces.
* Now uses Ruby 1.9 hash syntax.

## v0.1.1
#### 06-14-12

* Finally got around to putting this under source control.
* Added readme and rvmrc.

## v0.1.0
#### 06-13-12

* File/Directory names are now served as UTF-8 instead of ASCII-8BIT.
* Now requires Ruby 1.9.3p125 or higher (although, any 1.9 version should work).

## v0.0.2
#### 06-12-12

* Navigation breadcrumbs added.
* File/Directory blacklist added.
* Changes to behavior of how directories are found.

## v0.0.1
#### 06-11-12

* Initial release.
