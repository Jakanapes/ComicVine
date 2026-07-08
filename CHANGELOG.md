# Changelog

Notable changes to this project are documented in this file. The format is
based on [Keep a Changelog](https://keepachangelog.com/); dates for releases
before 2026 are taken from the git history.

## [0.2.0] — Unreleased

### Added

- Error hierarchy under `ComicVine::CVError`: `CVAPIError`, `CVHTTPError`
  (with `#status`), `CVRateLimitError`, `CVConnectionError`, and `CVParseError`.
- Connection timeouts (`open_timeout` 10s, `read_timeout` 30s), configurable via
  `ComicVine::API.open_timeout = ...` / `read_timeout = ...`.
- Automatic retries with exponential backoff on HTTP 420/429/5xx and connection
  failures; honors `Retry-After`. Configurable via `max_retries` and
  `retry_base_delay`.
- Custom User-Agent header, overridable via `ComicVine::API.user_agent = ...`.
- `respond_to_missing?` on `ComicVine::API` and `CVObject`, so `respond_to?`
  and `method(...)` work for dynamic methods.
- `ComicVine::API.reset_types_cache!` for tests.
- RuboCop and YARD configuration; API documentation comments.

### Changed

- JSON parsing uses the Ruby standard library; the gem now has **no runtime
  dependencies** (`multi_json`, `oj`, and `gson` removed).
- Class variables replaced with class-level instance variables; the `/types/`
  cache is guarded by a mutex and no longer poisoned by a failed fetch.
- `next_page`/`prev_page` return `self` on success and `nil` at either end,
  and preserve the original `filter`/`sort`/`field_list` options.
- Modernized gemspec (metadata URIs, `Dir` glob instead of `git ls-files`),
  RSpec 3 configuration, and WebMock-stubbed specs.

### Fixed

- Query values are URL-encoded (`CGI.escape`); search queries are no longer
  double-encoded.
- `search` no longer mutates the caller's options hash.
- `prev_page` offset math stepped by the current page's size instead of `limit`.
- `get_details` with an unknown type raises a descriptive `CVError` instead of
  `NoMethodError`.
- `CVObject#get_*` on a plain value returns the value instead of `nil`.
- `CVObject` readers are defined on the singleton class instead of polluting
  the shared class.

### Removed

- Travis CI configuration.
- Committed build artifacts (`coverage/`, packaged `.gem`, `.DS_Store`).

## [0.1.5] — 2017-03-25

- Use ComicVine URL with SSL.

## [0.1.4] — 2016-02-12

- Update ComicVine API URL.

## [0.1.1] — 2012-04-27

- Escape query on search; remove spaces from resources.

## [0.1.0] — 2012-04-24

- Fix small bug with types cache; full coverage with RSpec.

## [0.0.8] — 2012-04-18

- Fix bug exposing API key.

## [0.0.7] — 2012-04-18

- Fix bug with search.

## [0.0.6] — 2012-04-18

- Expose the helper methods; add `get_details_by_url`; allow `get_*` for any of
  the resource items returned in the body.

## [0.0.5] — 2012-04-12

- Behind-the-scenes cleanup. Pure Ruby implementation; `API.key` is set
  manually instead of read from a config file. Removed generator and railties.

## [0.0.4] — 2012-04-11

- Add `CVObjectList` to carry count vars from result. Simple pagination.
  Include `Enumerable` in the list classes.

## [0.0.3] — 2012-04-10

- Simple associations; error check on ComicVine response; allow options.

## [0.0.2] — 2012-04-09

- Create `CVObject`s from resource returns.

## [0.0.1] — 2012-04-09

- First check-in.
