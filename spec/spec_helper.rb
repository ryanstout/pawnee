require 'rspec'

libdir = File.expand_path(File.dirname(__FILE__) + "/../lib/pawnee")
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

RSpec.configure do |config|
  
end