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
    
    def initialize(*args)
      super
    end
    
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
      # Assigns the role for this class
      def self.role(role_name)
        @role = role_name
      end
    
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
        
        # Assign the role (will be overridden by role :something in the class)
        subclass.role(class_name)
      end
      
      def self.recipes
        @recipes
      end
      
      # Invokes all recipes that implement the passed in role
      def self.invoke_roles(server, roles, options={})
        # Check to make sure some recipes have been added
        if recipes.is_a?(Array)
          recipes.each do |recipe_class|
            role = recipe_class.instance_variable_get('@role').to_s
            
            if roles.include?(role)
              # This class matches the role, so we should run it
              recipe = recipe_class.new([], options)
              recipe.setup(server)
            end
          end
        end
      end
  end
end