# ComicVine

VERY simple first cut at a gem to interface with the ComicVine api.  http://api.comicvine.com/

## Installation

Add this line to your application's Gemfile:

    gem 'comic_vine'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install comic_vine
    
You will also need to have a ComicVine API key.

After installing gem run the generator

rails g comic_vine:install

This will install a keyfile at config/cv_key.yml.  Update this file with your own API key.

The generator also installs an initializer to capture the api key in a class variable for ComicVine::API

## Usage

works on a subset of the api actions

characters

chats

concepts

issues

locations

movies

objects

origins

persons

powers

promos

publishers

story_arcs

teams

videos

video_types

volumes


Calls to plurals return arrays of CVObjects:

ComicVine::API.characters

Calls to singulars require an id and return a CVObject:

ComicVine::API.volume 766

Search takes a resource type and a query string and returns an array of CVObjects

ComicVine::API.search 'volume', 'batman'

## ToDos
Limits and Offsets

Filtering

Error checking

Documentation

Tests

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
