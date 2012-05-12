require 'net/ssh'
require "pawnee/setup"
require "pawnee/version"
require "pawnee/file_proxy"

puts "Include main pawnee::base"
module Pawnee
  class Base
    attr_reader :connection
    # Proxy the file object, so all file operations can happen local
    # or remote
    
    # Connect to the remote server or run locally
    def connect
      @connection = Net::SSH.start('44dates.com', 'ubuntu')
    end
    
    def disconnect
      @connection.close
    end
    
    def file
      @file ||= Pawnee::FileProxy.new(connection)
    end
    
    # All recipies should subclass Pawnee::Base and implement setup to
    # install everything needed for the gem
    # setup should be able to be called multiple times
    def setup
      raise 'this gem does not implement the setup method'
    end
    
    # All recipies should also implement teardown to uninstall anything
    # that gets installed
    def teardown
      raise 'this gem does not implement the teardown method'
    end
  end
end