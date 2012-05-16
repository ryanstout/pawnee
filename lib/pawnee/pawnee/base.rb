require 'net/ssh'
require "pawnee/setup"
require "pawnee/version"
require 'thor'

module Pawnee
  class Base < Thor
    include Thor::Actions
    
    def initialize(destination_server)
      puts "ARGS: #{args.inspect}"
    end
    
    attr_reader :connection
    # Proxy the file object, so all file operations can happen local
    # or remote
    
    # Connect to the remote server or run locally
    # def connect
    #   @connection = Net::SSH.start('44dates.com', 'ubuntu')
    # end
    # 
    # def disconnect
    #   @connection.close
    # end
    
    # def remote_file
    #   @file ||= Pawnee::FileProxy.new(connection)
    # end
    
    # All recipies should subclass Pawnee::Base and implement setup to
    # install everything needed for the gem
    # setup should be able to be called multiple times
    desc "setup DESTINATION_SERVER", 'runs the recipe setup on the destination server'
    def setup(destination_server=nil)
      raise 'this gem does not implement the setup method'
    end
    
    # All recipies should also implement teardown to uninstall anything
    # that gets installed
    desc "teardown DESTINATION_SERVER", 'runs the recipe teardown on the destination server'
    def teardown(destination_server=nil)
      raise 'this gem does not implement the teardown method'
    end
  end
end