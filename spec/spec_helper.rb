require 'rspec'

libdir = File.expand_path(File.dirname(__FILE__) + "/../lib/pawnee")
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)


require 'simplecov'
SimpleCov.start do
  add_group 'Libraries', 'lib/pawnee/pawnee'
  add_group 'Specs', 'spec'
end


require 'pawnee/base'
require 'vagrant/vagrant'


RSpec.configure do |config|
  config.after(:suite) do
    unless ENV['TRAVIS']
      # Rollback the server
      puts "Roll back test server"
      # `cd spec/vagrant/ ; BUNDLE_GEMFILE=../../Gemfile bundle exec vagrant sandbox rollback`
    end
  end
end