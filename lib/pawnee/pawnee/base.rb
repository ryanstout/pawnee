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
      
      # Setup the destination_connection for this instance
      if options[:server]
        # TODO: option to share connections and pass in more options
        self.destination_connection = Net::SSH.start(options[:server], 'ubuntu')
      end
    end
    
    desc "setup", 'setup on the destination server'
    # All recipies should subclass Pawnee::Base and implement setup to
    # install everything needed for the gem
    # setup should be able to be called multiple times
    def setup
      raise 'this gem does not implement the setup method'
    end
    
    desc "teardown", 'teardown on the destination server'
    # All recipies should also implement teardown to uninstall anything
    # that gets installed
    def teardown
      raise 'this gem does not implement the teardown method'
    end

    
    private
      def self.global_options
        @global_options = true
        yield
        @global_options = false
      end
      
      def self.check_unknown_options?(config)
        false
      end
    
      def self.method_option(name, options={})
        scope = if options[:for]
          find_and_refresh_task(options[:for]).options
        else
          method_options
        end

        unless @global_options
          prefix = self.name.gsub(/[:][:][^:]+$/, '')[/[^:]+$/].downcase
          name = "#{prefix}_#{name}"
        end

        build_option(name, options, scope)
      end
      

      # Assigns the role for this class
      def self.role(role_name)
        @role = role_name
      end
      
      def self.class_role
        @role
      end
    
      # Inherited is called when a class inherits from Pawnee::Base, it then
      # sets up the class in the pawnee command cli, and sets up the namespace.
      # It also registeres the recipe so that it can be accessed later
      def self.inherited(subclass)
        super(subclass)
        
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
      def self.invoke_roles(task_name, roles, options={})
        # Check to make sure some recipes have been added
        if recipes.is_a?(Array)
          # Exclude classes that are not in this role
          if roles.to_sym == :all
            role_classes = recipes
          else
            role_classes = recipes.reject do |recipe_class|
              role = recipe_class.instance_variable_get('@role').to_s
            
              ![roles].flatten.map(&:to_s).include?(role)
            end
          end
          
          # # Get the list of all options we're using for this global setup
          # all_options = {}
          # role_classes.each do |recipe_class|
          #   all_options.merge!(recipe_class.tasks['setup'].options)
          # end

          requirements_met = true
          error_message = []
          role_classes.each do |recipe_class|
            # Make sure all of the options are met here, let server slide since we will
            # specify it from the servers option later
            required_options = recipe_class.tasks['setup'].options.reject {|k,v| !v.required? || k.to_s == 'server' }.keys.map(&:to_s)
            unspecified_options = required_options - options.keys.map(&:to_s)
            
            if unspecified_options.size > 0
              error_message << "The #{recipe_class.class_role} role requires the following: #{unspecified_options.join(', ')}"
              requirements_met = false
            end
          end
          
          raise Thor::InvocationError, error_message.join("\n") if !requirements_met

          
          role_classes.each do |recipe_class|
            # This class matches the role, so we should run it
            puts "OPTID: #{options.object_id}"
            recipe = recipe_class.new([], options)

            # puts "SETUP ON #{recipe_class.name}"
            puts "Call with server"
            # recipe.invoke(:setup)
            
            # Run the setup task, setting up the needed connections
            unless options[:servers]
              recipe.setup()
            else
              options[:servers].each do |server|
                # Set the server for this call
                options[:server] = server
                
                # Run the invoked task
                recipe.send(task_name.to_sym)
                
                # Remove the server
                options.delete(:server)
                
                # Copy back any updated options
                options = recipe.options
                
                # Close the connection
                if recipe.destination_connection
                  recipe.destination_connection.close
                  recipe.destination_connection = nil
                end
              end
            end
          end
        end
      end
  end
end