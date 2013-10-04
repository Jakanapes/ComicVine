[![Build Status](https://secure.travis-ci.org/Jakanapes/ComicVine.png?branch=master)](http://travis-ci.org/Jakanapes/ComicVine)

# ComicVine

VERY simple first cut at a gem to interface with the ComicVine api.  http://api.comicvine.com/

## Installation

Add this line to your application's Gemfile:

    gem 'comic_vine'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install comic_vine
    
You will also need to have a ComicVine API key.

## Usage

Requires that API key be set manually.  This is a breaking change from 0.0.4.

    ComicVine::API.key = xxxxxx


Calls to plurals return a CVObjectList, which contains the result array as well as the values from the return (total_count, offset, limit, resource).

    chars = ComicVine::API.characters

CVObjectLists include enumerable, so they can be looped.

    chars.each do |c|
    
Pagination will return nil if you are at either end of the list, otherwise it will update the object allowing for looping
    
    chars.next_page
    chars.prev_page

Calls to singulars require an id and return a CVObject:

    ComicVine::API.volume 766

Search takes a resource type or types, separated by a comma(ex. "volume,issue"), and a query string and returns a CVSearchList (also with pagination)

    results = ComicVine::API.search 'volume', 'batman'
    
Call fetch to retrieve the full object
    
    results.first.fetch

Pass in options as a hash

    ComicVine::API.characters {:limit=>5, :offset=>10}

There are associations.  Call the association by the key name, prefaced by get_ and the gem will return either a CVList or a CVObject from the API.

    volume = ComicVine::API.volume 766
    issues = volume.get_issues
    chars = volume.get_character_credits

Error responses from the API will raise a CVError with the error message


This gem is released under the MIT license, if you find it useful in your application, drop me a line and I'll post a link!


## ToDos
More Error checking

Documentation

Tests

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
