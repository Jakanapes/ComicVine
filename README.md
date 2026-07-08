# ComicVine

A simple Ruby interface to the [ComicVine API](https://comicvine.gamespot.com/api/).
Search for volumes, issues, characters, and other resources, or fetch them by id.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "comic_vine"
```

And then run `bundle install`, or install it directly:

```console
$ gem install comic_vine
```

You will also need a [ComicVine API key](https://comicvine.gamespot.com/api/).

## Usage

Set your API key first:

```ruby
ComicVine::API.key = "your-api-key"
```

Calls to plural resources return a `CVObjectList`, which carries the result
array along with the values from the response (`total_count`, `page_count`,
`offset`, `limit`):

```ruby
chars = ComicVine::API.characters
```

`CVObjectList` includes `Enumerable`, so lists can be looped:

```ruby
chars.each { |c| puts c.name }
```

Pagination updates the list in place and returns the list, or returns `nil` at
either end, so it can be used in a loop:

```ruby
chars.next_page
chars.prev_page
```

Calls to singular resources take an id and return a `CVObject`:

```ruby
ComicVine::API.volume 766
```

`search` takes a resource type or types (comma-separated, e.g.
`"volume,issue"`) and a query string, and returns a `CVSearchList` (also
paginated):

```ruby
results = ComicVine::API.search "volume", "batman"
```

Call `fetch` to retrieve the full object behind a search result or association:

```ruby
results.first.fetch
```

### Options: `limit`, `offset`, `filter`, `sort`, `field_list`

List and detail calls accept an options hash, passed through to the API as
query parameters (values are URL-encoded for you). The most useful ones:

```ruby
# Page size and starting offset
ComicVine::API.characters(limit: 5, offset: 10)

# Filter results — field:value pairs, comma-separated
ComicVine::API.volumes(filter: "name:Walking Dead")

# Sort by a field — field:asc or field:desc
ComicVine::API.issues(sort: "cover_date:desc")

# Only return the fields you need (faster, smaller responses)
ComicVine::API.characters(field_list: "name,id,image")
```

These options are remembered across `next_page`/`prev_page`, so a filtered or
sorted list stays filtered and sorted while you page through it. See the
[ComicVine API documentation](https://comicvine.gamespot.com/api/documentation)
for the fields each resource supports.

### Associations

Call an association by its key name, prefaced by `get_`, and the gem will
return either an array of fetched objects or a `CVObject` from the API:

```ruby
volume = ComicVine::API.volume 766
issues = volume.get_issues
chars  = volume.get_character_credits
```

### Errors

All errors raised by the gem inherit from `ComicVine::CVError`:

| Class | Raised when |
| --- | --- |
| `CVAPIError` | the API answers with an error status code (bad key, not found, …) |
| `CVHTTPError` | the server answers with a non-2xx HTTP status (`#status` has the code) |
| `CVRateLimitError` | HTTP 420/429 persists after retries (~200 requests/resource/hour) |
| `CVConnectionError` | the connection fails or times out after all retries |
| `CVParseError` | the response body is not valid JSON |

### Configuration

Timeouts, retries, and the User-Agent header can be tuned on `ComicVine::API`:

```ruby
ComicVine::API.open_timeout     = 10    # seconds (default 10)
ComicVine::API.read_timeout     = 30    # seconds (default 30)
ComicVine::API.max_retries      = 3     # retries on 420/429/5xx and connection errors
ComicVine::API.retry_base_delay = 1.0   # exponential backoff base, honors Retry-After
ComicVine::API.user_agent       = "my-app/1.0"
```

## Development

Run the test suite with `bundle exec rake spec`, the linter with
`bundle exec rubocop`, and generate API docs with `bundle exec yard`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

This gem is released under the [MIT license](LICENSE). If you find it useful
in your application, drop me a line and I'll post a link!
