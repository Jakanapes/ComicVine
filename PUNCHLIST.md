# ComicVine Gem — Punchlist

Review date: 2026-07-07 · v0.1.5 · No code changed, review only.

## Likely broken right now — ✅ all fixed 2026-07-07

1. ~~**Specs stub `http://` but the code now uses `https://`**~~ ✅ stubs updated to `https://`
2. ~~**RSpec config is dead**~~ ✅ modern RSpec 3 config (`expect` syntax, `disable_monkey_patching!`)
3. ~~**Travis CI is gone**~~ ✅ removed
4. ~~**One spec hits the live API**~~ ✅ invalid-key test stubbed with WebMock

## Bugs / correctness — ✅ all fixed 2026-07-07 (specs updated)

5. ~~`comic_vine.rb:40` and `cv_object.rb:34` — bare `elsif` with `super` used as the *condition*.~~ ✅ `else`
6. ~~`CVObject#method_missing`: `get_foo` on a plain value silently returns `nil`.~~ ✅ returns the value
7. ~~`get_details` with an unknown type → `NoMethodError` on `nil['id']`.~~ ✅ raises `CVError` naming the type
8. ~~`build_query` doesn't URL-encode values.~~ ✅ `CGI.escape` (and `search` no longer pre-escapes `query`, avoiding double-encoding)
9. ~~`search` mutates the caller's `opts` hash.~~ ✅ uses `merge`
10. ~~`prev_page` math uses the *current* page's `@page_count`.~~ ✅ offsets step by `@limit` (clamped at 0); `update_ivals` also refreshes `@page_count` now
11. ~~`CVObjectList#next_page` drops original filters/sort/field_list.~~ ✅ lists remember their opts and merge them on next/prev (search lists too)
12. ~~`v.first.key?(...)` raises if an array contains non-hashes.~~ ✅ `kind_of?(Hash)` guard
13. ~~`attr_reader` via `class_eval` pollutes the shared `CVObject` class.~~ ✅ readers defined on the singleton class; `respond_to_missing?` added for `get_*`
14. ~~`next_page`/`prev_page` inconsistent return contract.~~ ✅ return `self` on success, `nil` at the ends

## Robustness gaps — ✅ all fixed 2026-07-08 (specs added)

15. ~~No HTTP error handling: `Net::HTTP.get` happily parses a 404/500/HTML body; JSON parse errors (`MultiJson::ParseError`) escape unrescued.~~ ✅ status checked; error hierarchy: `CVAPIError`, `CVHTTPError` (with `#status`), `CVRateLimitError`, `CVConnectionError`, `CVParseError` — all `< CVError`
16. ~~No timeouts — a hung connection hangs the caller indefinitely.~~ ✅ `open_timeout` (10s) / `read_timeout` (30s), configurable via `ComicVine::API.open_timeout = ...`
17. ~~No retry/backoff, no handling of ComicVine's rate limits (~200 req/resource/hour) or 420 responses.~~ ✅ retries 420/429/5xx and connection failures with exponential backoff (`max_retries`, `retry_base_delay` configurable); honors `Retry-After`; exhausted rate limits raise `CVRateLimitError`
18. ~~No custom User-Agent — ComicVine/GameSpot has been known to block default library UAs.~~ ✅ `comic_vine gem/x.y.z (Ruby/x.y.z)`, overridable via `ComicVine::API.user_agent=`
19. ~~Class variables (`@@key`, `@@types`) = global mutable state.~~ ✅ class-level instance variables + `Mutex` around the types cache; still one key per process — full instance-based client deliberately deferred to "new functionality"
20. ~~First call to any dynamic method fetches `/types/` — hidden extra API call; failure there makes every method look like NoMethodError.~~ ✅ types failures raise a `CVError` subclass naming the `/types/` call and don't poison the cache (retried on next call); `reset_types_cache!` added for tests
21. ~~`method_missing` without `respond_to_missing?` — `respond_to?(:issues)` and `method(:issues)` lie.~~ ✅ `respond_to_missing?` on `API` (returns false instead of raising if types can't be fetched)

## Housekeeping — ✅ all fixed 2026-07-08

22. ~~`coverage/`, `comic_vine-0.1.4.gem`, `.DS_Store` are committed — gitignore them.~~ ✅ they were untracked (already ignored), just stale on disk — deleted; `.gitignore` deduped and tidied
23. ~~Gemfile.lock pins comic_vine 0.1.4; deps ancient.~~ ✅ lock was already regenerated (modern rspec/webmock, bundler 2.7); updated to 0.2.0 / no runtime deps — run `bundle install` locally to pick up rubocop + yard
24. ~~`multi_json` dependency is unnecessary today.~~ ✅ stdlib `json` (`JSON.parse` / `JSON::ParserError`); multi_json/oj/gson removed — gem has **zero runtime deps**
25. ~~gemspec: missing metadata; `git ls-files` discouraged.~~ ✅ metadata URIs (source, changelog, bug tracker, mfa_required), `Dir` glob file list, `test_files` dropped, `required_ruby_version` kept at ≥ 3.4
26. ~~`changelog` → conventional `CHANGELOG.md` with dates.~~ ✅ Keep-a-Changelog format, dates recovered from git history; 0.2.0 unreleased section summarizes all punchlist fixes
27. ~~README: dead links, no docs for options.~~ ✅ rewritten: gamespot API links, `filter`/`sort`/`field_list` examples, error-class table, timeout/retry/UA config, fixed invalid `characters {...}` example
28. ~~No RuboCop, no YARD/RDoc.~~ ✅ `.rubocop.yml` (lint-strict, style-permissive — run `rubocop -a` locally to tighten), `.yardopts`, rake tasks (`rubocop`, `doc`), YARD comments on the public API, `frozen_string_literal` everywhere

## Suggested new functionality

- **Instance-based client**: `cv = ComicVine::Client.new(api_key: ..., timeout: ...)` — multiple keys, thread-safe, testable. Keep `ComicVine::API` as a thin deprecated shim.
- **Modern CI**: GitHub Actions matrix on Ruby 3.1–3.4.
- **Auto-pagination**: `list.each_page`, `ComicVine::API.issues.find_each { |i| ... }` (lazy Enumerator across pages).
- **First-class `field_list`/`filter`/`sort`** kwargs with proper encoding, so pagination preserves them.
- **Rate-limit awareness**: configurable throttle + exponential backoff on 420/5xx.
- **Pluggable cache** (in-memory default, Rails.cache adapter) for types and detail fetches.
- **Typed resources** (Issue, Volume, Character…) with parsed dates and defined associations instead of pure method_missing.
- **`respond_to_missing?`** or pre-generated methods from the types list.
- **Raw response access** (`.raw`) and a `to_h` on CVObject.
- **Logging/instrumentation hook** (log each request, duration, rate-limit status).
- **CLI** (`comicvine search volume "batman"`) — nice demo and debugging tool.
- **Faraday adapter option** for middleware, persistent connections, and easier stubbing.

## Suggested order of attack

Fix the test suite first (1–4) so everything else has a safety net → correctness bugs (5–14) → robustness (15–21) → housekeeping (22–28) → new features. Items 13 and 19 together motivate the instance-based client; doing that early makes most robustness work cleaner.

Note (2026-07-08): sandbox couldn't reach rubygems.org, so 15–21 were verified with a standalone stubbed-HTTP minitest harness (13 tests green) plus `ruby -c`. New rspec examples were added to `spec/comic_vine_spec.rb` — run `bundle exec rspec` locally to confirm.

Note (2026-07-08, housekeeping): 22–28 done. Same sandbox limits, so verification was `ruby -c` on everything, a gemspec load check, and a 6-test stubbed harness (JSON swap, frozen-string safety, pagination, query encoding — all green). After pulling, run `bundle install` (adds rubocop + yard to the lock) then `bundle exec rspec` and `bundle exec rubocop`.
