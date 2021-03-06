require 'net/ssh'
require 'thor'
require 'thor-ssh'
require "pawnee/setup"
require "pawnee/version"
require 'pawnee/actions'
require 'pawnee/parser/options'
require 'active_support/core_ext/hash/deep_merge'
require 'pawnee/roles'
require 'pawnee/invocation'
require 'pawnee/modified'
require 'pawnee/ssh_connection'

module Pawnee
  # The pawnee gem provides the Pawnee::Base class, which includes actions
  # from the thor gem, thor-ssh gem, and the pawnee gem its self.  Any class
  # that inherits from Pawnee::Base will automatically be registered as a
  # recipe.
  class Base < Thor
    include Thor::Actions
    include ThorSsh::Actions
    include Pawnee::Actions
    include Pawnee::Invocation
    include Pawnee::Modified
    include Pawnee::SshConnection
    include Roles
    
    attr_accessor :server, :server_options, :setup_with_connection
    
    # Creates an instance of the pawnee recipe
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
      pawnee_setup_invocations(args, options, config)

      pawnee_setup_actions(args, options, config) do
        
        # We need to change Thor::Options to use Pawnee::Options on 
        # invoke so we can include the defaults from the config file,
        # so here we copy in the initialize from thor/base.rb#initialize
        parse_options = self.class.class_options
      
        # The start method splits inbound arguments at the first argument
        # that looks like an option (starts with - or --). It then calls
        # new, passing in the two halves of the arguments Array as the
        # first two parameters.
      
        if options.is_a?(Array)
          task_options  = config.delete(:task_options) # hook for start
          parse_options = parse_options.merge(task_options) if task_options
          array_options, hash_options = options, {}
        else
          # Handle the case where the class was explicitly instantiated
          # with pre-parsed options.
          array_options, hash_options = [], options
        end
        
        # Let Thor::Options parse the options first, so it can remove
        # declared options from the array. This will leave us with
        # a list of arguments that weren't declared.
        # --- We change Thor::Options to Pawnee::Options to pull in
        # the config default's
        opts = Pawnee::Options.new(parse_options, hash_options)
        self.options = opts.parse(array_options)
      
        # If unknown options are disallowed, make sure that none of the
        # remaining arguments looks like an option.
        opts.check_unknown! if self.class.check_unknown_options?(config)
      
        # Add the remaining arguments from the options parser to the
        # arguments passed in to initialize. Then remove any positional
        # arguments declared using #argument (this is primarily used
        # by Thor::Group). Tis will leave us with the remaining
        # positional arguments.
        thor_args = Thor::Arguments.new(self.class.arguments)
        thor_args.parse(args + opts.remaining).each { |k,v| send("#{k}=", v) }
        args = thor_args.remaining
      
        @args = args
        #-- end copy from thor/base.rb#initialize
      end
    end
    
    
    
    desc "setup", 'setup on the destination server'
    # All recipies should subclass Pawnee::Base and implement setup to
    # install everything needed for the gem.
    # Setup should be able to be called multiple times
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
      self.name.gsub(/[:][:]Base$/, '').gsub(/^[^:]+[:][:]/, '').gsub(/([A-Z]+)([A-Z][a-z])/,'\1-\2').gsub(/([a-z\d])([A-Z])/,'\1-\2').downcase
    end
    
    no_tasks {
      
      # # Invoke the given task if the given args.
      # TODO: This method needs some refactoring
      def invoke_task(task, *args) #:nodoc:
        current = @_invocations[self.class]

        # Default force for actions in options
        # TODO: Should this get set in invoke?
        options[:force] ||= true

        unless current.include?(task.name)
          current << task.name
          
          puts " Run task: #{self.class.class_role.to_s} - #{task.name} ".center(80, '*')

          # Setup the server connections before we run the task
          servers = options[:servers] || options['servers']

          # Don't run multiple times if:
          # 1. they don't have any servers (then run locally)
          # 2. the call is coming from the main CLI
          # 3. they are calling a help task
          if !servers || self.class == Pawnee::CLI || task.name == 'help'
            # No servers, just run locally
            task.run(self, *args)
          else
            first_invoke = true
            # Create a list of instances that we want to run this task
            instances = []
            
            # Run the setup task, setting up the needed connections
            servers.each do |server|
              # Only run on this server if the server supports the current recipe's
              # role.
              next unless server.is_a?(String) || server.is_a?(Net::SSH::Connection::Session) || (server['roles'] && server['roles'].include?(self.class.class_role))

              if first_invoke
                instance = self
                first_invoke = false
              else
                # Make a clone (since we want to run self on different threads)
                # TODO: Look into how deep we need to make this clone (options may be 
                # shared right now)
                instance = self.clone
              end
              # Setup the connection to the server
              if server.is_a?(Net::SSH::Connection::Session)
                instance.destination_connection = server
                instance.server = server.host
                instance.setup_with_connection = true
              elsif server.is_a?(String)
                # Server name is a string, asume ubuntu
                instance.destination_connection = Net::SSH.start(server, 'ubuntu')
                instance.server = server
              else
                # Server is a hash
                instance.destination_connection = Net::SSH.start(server['domain'], server['user'] || 'ubuntu')
                instance.server = server['domain']
                instance.server_options = server
              end
              
              # Setup server options if not setup already
              instance.server_options = instance.server_options || {}
              
              # Add the instance to the list of instances to run on
              instances << instance
            end
            
            # Take the list of instances and invoke the task on each one in a seperate thread
            threads = []
            
            instances.each do |instance|
              threads << Thread.new do
                # Run the task
                task.run(instance, *args)

                # Remove the server
                instance.server = nil

                # Close the connection
                if instance.destination_connection
                  # Close the conection only if we created it.  If it was passed in as a connection
                  # then the creator is responsible for closing it
                  instance.destination_connection.close unless instance.setup_with_connection
                  instance.destination_connection = nil
                end
              end
            end
            
            # Wait for threads to finish
            threads.each(&:join)
          end
        end
      end

      # Whenever say is used, also print out the server name
      def say(*args)
        text = args[0]
        name = (server_options && server_options['name']) || server
        text = "[#{name}]:\t" + text.to_s if name
        super(text, *args[1..-1])
      end
      
      def say_status(*args)
        text = args[0]
        name = (server_options && server_options['name']) || server
        text = "[#{name}]:\t" + text.to_s if name
        super(text, *args[1..-1])        
      end
    }
    
    private      
      def self.check_unknown_options?(config)
        false
      end
      

      # Inherited is called when a class inherits from Pawnee::Base, it then
      # sets up the class in the pawnee command cli, and sets up the namespace.
      # It also registeres the recipe so that it can be accessed later
      def self.inherited(subclass)
        super(subclass)
        
        # Make sure cli has been loaded at this point
        require 'pawnee/cli' unless defined?(Pawnee) && defined?(Pawnee::CLI)
        
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
        
        require 'pawnee/cli' unless defined?(Pawnee) && defined?(Pawnee::CLI)
        
        # Take all of the setup options and copy them to the main 
        # CLI setup task
        meth = meth.to_s
        if meth != 'gem' && Pawnee::CLI.tasks[meth]
          Pawnee::CLI.tasks[meth].options.merge!(self.tasks[meth].options)
        end
      end
      

  end
end