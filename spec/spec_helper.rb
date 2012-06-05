require 'rspec'

libdir = File.expand_path(File.dirname(__FILE__) + "/../lib/pawnee")
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'pawnee/base'
require 'vagrant/vagrant'

RSpec.configure do |config|
  config.after(:suite) do
    # Rollback the server
    puts "Roll back test server"
    `cd spec/vagrant/ ; BUNDLE_GEMFILE=../../Gemfile bundle exec vagrant sandbox rollback`
  end
end