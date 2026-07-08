# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
  # rubocop not installed
end

begin
  require "yard"
  YARD::Rake::YardocTask.new(:doc)
rescue LoadError
  # yard not installed
end

task default: :spec
