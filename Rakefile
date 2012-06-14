#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end


require 'rspec/core/rake_task'

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  if ENV['TRAVIS']
    # Unfortunately we can't run vagrant on travis, 
    # so this limits us quite a bit on what tests 
    # we can run
    t.pattern = "./spec/base_spec.rb"
  else
    t.pattern = "./spec/**/*_spec.rb"
  end
end

# ENV['TRAVIS']

# task :default => :test