require 'net/ssh'
require "pawnee/setup"
require "pawnee/version"
require 'thor'
require 'thor-ssh'
require 'pawnee/actions'
require 'pawnee/thor/parser/options'
require 'active_support/core_ext/hash/deep_merge'
require 'pawnee/roles'

module Pawnee
  # The pawnee gem provides the Pawnee::Base class, which includes actions
  # from the thor gem, thor-ssh gem, and the pawnee gem its self.  Any class
  # that inherits from Pawnee::Base will automatically be registered as a
  # recipe.
  class Base < Thor
    include Thor::Actions
    include ThorSsh::Actions
    include Pawnee::Actions
    include Roles
    
    attr_accessor :server
    
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
    
    no_tasks {
      # Whenever say is used, also print out the server name
      def say(*args)
        text = args[0]
        text = "[#{server}]:\t" + text
        super(text, *args[1..-1])
      end
    }
    
    private
      def self.global_options
        @global_options = true
        yield
        @global_options = false
      end
      
      def self.check_unknown_options?(config)
        false
      end
    
    
      # Add options to create global method_options, otherwise
      # they are now prefixed by the recipe name by default
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
      

      # Inherited is called when a class inherits from Pawnee::Base, it then
      # sets up the class in the pawnee command cli, and sets up the namespace.
      # It also registeres the recipe so that it can be accessed later
      def self.inherited(subclass)
        super(subclass)
        
        # Make sure cli has been loaded at this point
        require 'pawnee/cli'
        
        # Skip the main CLI class
        return if subclass == Pawnee::CLI
        
        # Get the name of the parent module, which should what we want to register
        # this class unser
        class_name = subclass.gem_name
        subclass.namespace(class_name)
        
        # Register the class with the namespace
        Pawnee::CLI.register subclass, class_name.to_sym, class_name, "Setup #{class_name} on the remote server"
        
        @recipes ||= []
        @recipes << subclass
        
        # Assign the default role (can be overridden by 'role :something' in the class)
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
        meth = meth.to_s
        if meth != 'gem' && Pawnee::CLI.tasks[meth]
          Pawnee::CLI.tasks[meth].options.merge!(self.tasks[meth].options)
        end
      end
      

  end
end