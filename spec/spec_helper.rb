# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper.rb"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
require 'simplecov'
SimpleCov.start

require 'comic_vine'
#require 'webmock'
require 'webmock/rspec'


RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  #config.filter_run :focus
end

TYPES_BODY = '{"number_of_page_results": 17, "status_code": 1, "error": "OK", "results": [{"detail_resource_name": "issue", "id": 37, "list_resource_name": "issues"}, {"detail_resource_name": "volume", "id": 49, "list_resource_name": "volumes"}], "limit": 17, "offset": 0, "number_of_total_results": 17}'

ISSUE_BODY = '{"number_of_page_results": 1, "status_code": 1, "error": "OK", "results": {"site_detail_url": "http://www.comicvine.com/gizmo-/37-145830/", "id": 145830, "volume": {"api_detail_url": "http://www.comicvine.com/api/volume/24708/", "id": 24708, "name": "Gizmo"}, "publish_year": null}, "limit": 1, "offset": 0, "number_of_total_results": 1}'

ISSUES_BODY_1 = '{"number_of_page_results": 2, "status_code": 1, "error": "OK", "results": [{"api_detail_url": "http://www.comicvine.com/api/issue/6/", "site_detail_url": "http://www.comicvine.com/chamber-of-chills-magazine-man-in-the-hood-the-lost-race-the-man-germ-the-things/37-6/", "description": "", "deck": "", "aliases": "", "issue_number": "13.00", "publish_year": 1952, "has_staff_review": false, "date_added": "2008-06-06 11:10:16", "publish_day": null, "publish_month": 10, "id": 6, "name": "Man In the Hood;  The Lost Race; The Man Germ;  The Things; "}, {"api_detail_url": "http://www.comicvine.com/api/issue/7/", "site_detail_url": "http://www.comicvine.com/fighting-fronts-/37-7/", "description": "", "deck": "", "aliases": "", "issue_number": "3.00", "publish_year": 0, "has_staff_review": false, "date_added": "2008-06-06 11:10:16", "publish_day": null, "publish_month": 0, "id": 7, "name": ""}], "limit": 2, "offset": 0, "number_of_total_results": 4}'

ISSUES_BODY_2 = '{"number_of_page_results": 2, "status_code": 1, "error": "OK", "results": [{"api_detail_url": "http://www.comicvine.com/api/issue/6/", "site_detail_url": "http://www.comicvine.com/chamber-of-chills-magazine-man-in-the-hood-the-lost-race-the-man-germ-the-things/37-6/", "description": "", "deck": "", "aliases": "", "date_last_updated": "2009-01-27 12:47:44", "volume": {"api_detail_url": "http://www.comicvine.com/api/volume/1487/", "id": 1487, "name": "Chamber of Chills Magazine"}, "issue_number": "13.00", "publish_year": 1952, "has_staff_review": false, "date_added": "2008-06-06 11:10:16", "publish_day": null, "publish_month": 10, "id": 6, "name": "Man In the Hood;  The Lost Race; The Man Germ;  The Things; "}, {"api_detail_url": "http://www.comicvine.com/api/issue/7/", "site_detail_url": "http://www.comicvine.com/fighting-fronts-/37-7/", "description": "", "deck": "", "aliases": "", "date_last_updated": "2008-06-06 11:32:53", "volume": {"api_detail_url": "http://www.comicvine.com/api/volume/1488/", "id": 1488, "name": "Fighting Fronts!"}, "issue_number": "3.00", "publish_year": 0, "has_staff_review": false, "date_added": "2008-06-06 11:10:16", "publish_day": null, "publish_month": 0, "id": 7, "name": ""}], "limit": 2, "offset": 2, "number_of_total_results": 4}'

VOLUME_BODY = '{"number_of_page_results": 1, "status_code": 1, "error": "OK", "results": {"id": 24708, "issues": [{"api_detail_url": "http://www.comicvine.com/api/issue/145830/", "issue_number": "1.00", "id": 145830, "name": " "}]}, "limit": 1, "offset": 0, "number_of_total_results": 1}'


SEARCH_BODY_1 = '{"number_of_page_results": 1, "status_code": 1, "error": "OK", "results": [{"publisher": {"api_detail_url": "http://www.comicvine.com/api/publisher/517/", "id": 517, "name": "Mirage"}, "start_year": 1985, "description": "", "deck": "", "last_issue": null, "date_last_updated": "2010-07-04 20:51:17", "first_issue": null, "api_detail_url": "http://www.comicvine.com/api/volume/24708/", "count_of_issues": 6, "id": 24708, "date_added": "2008-12-12 16:58:16", "aliases": "", "site_detail_url": "http://www.comicvine.com/gizmo/49-24708/", "resource_type": "volume", "name": "Gizmo"}], "limit": 1, "offset": 0, "number_of_total_results": 2}'

SEARCH_BODY_2 = '{"number_of_page_results": 1, "status_code": 1, "error": "OK", "results": [{"publisher": {"api_detail_url": "http://www.comicvine.com/api/publisher/517/", "id": 517, "name": "Mirage"}, "start_year": null, "description": "", "deck": "Mirage volume starring Fugitoid and Gizmo", "last_issue": null, "date_last_updated": "2010-04-28 14:24:46", "first_issue": null, "api_detail_url": "http://www.comicvine.com/api/volume/32839/", "count_of_issues": 2, "id": 32839, "date_added": "2010-04-28 14:22:46", "aliases": "", "site_detail_url": "http://www.comicvine.com/gizmo-and-the-fugitoid/49-32839/", "resource_type": "volume", "name": "Gizmo and the Fugitoid"}], "limit": 1, "offset": 1, "number_of_total_results": 2}'
