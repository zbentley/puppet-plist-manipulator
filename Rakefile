#require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'rspec/core/rake_task'
require 'rspec'

def get_pattern_from_args(args)
  pattern = args[:pattern] || ""

  if pattern.end_with? ".rb"
    returnvalue = "**/*#{args[:pattern]}"
  else
    returnvalue = "**/*#{args[:pattern]}*{,/**}_spec.rb"
  end
  return returnvalue
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.ignore_paths = ["spec/**/*.pp", "pkg/**/*.pp"]

desc "Validate manifests, templates, and ruby files"
task :validate do
  Dir['manifests/**/*.pp'].each do |manifest|
    sh "puppet parser validate --noop #{manifest}"
  end
  Dir['spec/**/*.rb','lib/**/*.rb'].each do |ruby_file|
    sh "ruby -c #{ruby_file}" unless ruby_file =~ /spec\/fixtures/
  end
  Dir['templates/**/*.erb'].each do |template|
    sh "erb -P -x -T '-' #{template} | ruby -c"
  end
end

RSpec::Core::RakeTask.new(:acceptance_internal, [:pattern]) do |t, args| 
  t.pattern = get_pattern_from_args(args)
  t.pattern = "spec/acceptance/#{t.pattern}"
  unless t.pattern  =~ /selftest/
    t.exclude_pattern = "spec/acceptance/selftest/**"
  end
end

# Acceptance tests require symlinks created by spec_prep, so run it after them.
task :acceptance_internal => [:spec_prep]
Rake::Task[:acceptance_internal].clear_comments()
Rake::Task[:acceptance_internal].enhance do
  Rake::Task[:spec_clean].invoke
end

desc "Run local acceptance tests"
task(:acceptance, [:pattern]) do |t, args|
  Rake::Task[:acceptance_internal].invoke(args[:pattern])
end

# Blow away and re-create some of the helpers from the puppetlabs spec helper.
# This is done to allow an optional "pattern" regex that can be used to only run
# some subset of tests by name.
Rake::Task[:spec_standalone].clear
desc "Run spec tests on an existing fixtures directory"
RSpec::Core::RakeTask.new(:spec_standalone, [:pattern]) do |t, args|
  pattern = get_pattern_from_args(args)
  t.pattern = "spec/{classes,defines,unit,functions,hosts,integration}/**/#{pattern}"
end

Rake::Task[:spec].clear
desc "Run spec tests in a clean fixtures directory"
RSpec::Core::RakeTask.new(:spec, [:pattern]) do |t, args|
  Rake::Task[:spec_prep].invoke
  Rake::Task[:spec_standalone].invoke(args)
  Rake::Task[:spec_clean].invoke
end