require 'net/ssh'
require "pawnee/setup"
require "pawnee/version"
require 'thor'
require 'thor-ssh'
require 'pawnee/actions/package'
require 'pawnee/actions/compile'

module Pawnee
  class Base < Thor
    include Thor::Actions
    include ThorSsh::Actions
    include Pawnee::Actions
    
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