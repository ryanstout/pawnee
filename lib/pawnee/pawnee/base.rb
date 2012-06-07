require 'net/ssh'
require "pawnee/setup"
require "pawnee/version"
require 'thor'
require 'thor-ssh'
require 'pawnee/actions'
require 'pawnee/thor/parser/options'
require 'pawnee/cli'
require 'active_support/core_ext/hash/deep_merge'


module Pawnee
  # The pawnee gem provides the Pawnee::Base class, which includes actions
  # from the thor gem, thor-ssh gem, and the pawnee gem its self.  Any class
  # that inherits from Pawnee::Base will automatically be registered as a
  # recipe.
  class Base < Thor
    include Thor::Actions
    include ThorSsh::Actions
    include Pawnee::Actions
    
    # Calls the thor initializers, then if :server is passed in as 
    # an option, it will set it up
    #
    # ==== Parameters
    # args<Array[Object]>:: An array of objects. The objects are applied to their
    #                       respective accessors declared with <tt>argument</tt>.
    #
    # options<Hash>:: An options hash that will be available as self.options.
    #                 The hash given is converted to a hash with indifferent
    #                 access, magic predicates (options.skip?) and then frozen.
    #
    # config<Hash>:: Configuration for this Thor class.
    #    def initialize(*args)
    #
    # ==== Options
    #  :server  -  This can be:
    #                1) a connected ssh connection (created by Net::SSH.start)
    #                2) an Array of options to pass to Net::SSH.start
    #                3) a domain name for the first argument to Net::SSH.start
    def initialize(args=[], options={}, config={})
      super
      
      # Setup the destination_connection for this instance
      if self.options[:server]
        server = self.options[:server]
        
        # Setup the connection based on the tye of option passed in
        if server.is_a?(Net::SSH::Connection::Session)
          self.destination_connection = server
        elsif server.is_a?(Array)
          self.destination_connection = Net::SSH.start(*server)
        else
          # TODO: add a way to pass in the user
          self.destination_connection = Net::SSH.start(self.options[:server], 'ubuntu')
        end
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

    # Guess the gem name based on the class name
    def self.gem_name
      self.name.gsub(/[:][:][^:]+$/, '').gsub(/^[^:]+[:][:]/, '').gsub('::', '-').downcase
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
          prefix = self.gem_name.gsub('-', '_')
          name = "#{prefix}_#{name}".to_sym
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
        
        # Skip the main CLI class
        return if subclass == Pawnee::CLI
        
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

      # Pulls in the configuration options from the local path (relative to the Gemfile)
      # Usually this is also the rails config directory
      def self.config_options
        return @config_options if @config_options
        if defined?(Bundler)
          @config_options = {}
          require 'psych' rescue nil
          require 'yaml'
          
          config_file = File.join(File.dirname(Bundler.default_gemfile), '/config/pawnee.yml')
          if File.exists?(config_file)
            options = YAML.load(File.read(config_file))
            # Change keys to sym's
            options = options.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo }
            
            @config_options.deep_merge!(options)
          end
        end
        
        return @config_options
      end
      
      # Fire this callback whenever a method is added. Added methods are
      # tracked as tasks by invoking the create_task method.
      def self.method_added(meth)
        super
        
        # Take all of the setup options and copy them to the main 
        # CLI setup task
        if meth.to_s == 'setup'
          Pawnee::CLI.tasks['setup'].options.merge!(self.tasks['setup'].options)
        end
      end
      
      # Returns the recipe classes in order based on the Gemfile order
      def self.ordered_recipes
        return @ordered_recipes if @ordered_recipes
        names = Bundler.load.dependencies.map(&:name)
        
        recipe_pool = recipes.dup.inject({}) {|memo,recipe| memo[recipe.gem_name] = recipe ; memo }
        
        @ordered_recipes = []
        names.each do |name|
          if recipe_pool[name]
            @ordered_recipes << recipe_pool[name]
            recipe_pool.delete(name)
          end
        end
        
        # Add the remaining recipes (load them after everything else)
        @ordered_recipes += recipe_pool.values
        
        return @ordered_recipes
      end
      
      
      # Invokes all recipes that implement the passed in role
      def self.invoke_roles(task_name, roles, options={})
        # Merge passed in options into the config file options
        options = config_options.dup.deep_merge!(options)
        
        # Check to make sure some recipes have been added
        if ordered_recipes.size == 0
          raise Thor::InvocationError, 'no recipes have been defined'
        else
          # Exclude classes that are not in this role
          if (roles.is_a?(Array) && roles.size == 0) || roles == :all
            role_classes = ordered_recipes
          else
            role_classes = ordered_recipes.reject do |recipe_class|
              role = recipe_class.instance_variable_get('@role').to_s
            
              ![roles].flatten.map(&:to_s).include?(role)
            end
          end

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
            recipe = recipe_class.new([], options)
            
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