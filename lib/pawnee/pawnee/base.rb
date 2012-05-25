require 'net/ssh'
require "pawnee/setup"
require "pawnee/version"
require 'thor'
require 'thor-ssh'
require 'pawnee/actions'
require 'pawnee/thor/parser/options'

module Pawnee
  # The pawnee gem provides the Pawnee::Base class, which includes actions
  # from the thor gem, thor-ssh gem, and the pawnee gem its self.  Any class
  # that inherits from Pawnee::Base will automatically be registered as a
  # recipe.
  class Base < Thor
    include Thor::Actions
    include ThorSsh::Actions
    include Pawnee::Actions
    
    desc "setup SERVER", 'setup on the destination server'
    # All recipies should subclass Pawnee::Base and implement setup to
    # install everything needed for the gem
    # setup should be able to be called multiple times
    #
    # === Parameters
    # server<String>:: A hostname pointing to a server where pawnee can ssh into
    def setup(server)
      raise 'this gem does not implement the setup method'
    end
    
    desc "teardown SERVER", 'teardown on the destination server'
    # All recipies should also implement teardown to uninstall anything
    # that gets installed
    #
    # === Parameters
    # server<String>:: A hostname pointing to a server where pawnee can ssh into
    def teardown(server)
      raise 'this gem does not implement the teardown method'
    end
    
    
    private
      # Inherited is called when a class inherits from Pawnee::Base, it then
      # sets up the class in the pawnee command cli, and sets up the namespace.
      # It also registeres the recipe so that it can be accessed later
      def self.inherited(subclass)
        # Get the name of the parent module, which should what we want to register
        # this class unser
        class_name = subclass.name.gsub(/[:][:][^:]+$/, '')[/[^:]+$/].downcase
        subclass.namespace(class_name)
        
        # Register the class with the namespace
        Pawnee::CLI.register subclass, class_name.to_sym, class_name, "Setup #{class_name} on the remote server"
        
        @recipes ||= []
        @recipes << subclass
      end
  end
end