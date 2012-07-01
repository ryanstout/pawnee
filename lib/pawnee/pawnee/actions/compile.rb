module Pawnee
  module Actions
    
    # Takes a tar.gz or zip file and unzips it, and runs the 
    # standard ./configure, make, sudo make install
    #
    # It attempts to raise an exception at any compilation 
    # failure.
    #
    #  compile 'http://nginx.org/download/nginx-1.2.0.tar.gz'
    #
    # === Parameters
    # url<String>:: The url to download
    # temp_dir<String>:: Where the compilation should take place
    # options<Hash>:: Hash of options, see below
    #
    # === Options
    # #compile requires that you either specify a :bin_file option
    # that the method can check for on the remote system, or that 
    # you pass a block that returns true if the app has already been
    # installed
    #
    # :bin_file   - the name of an executable that the method can check for in the path
    # :config_options  - a string of options to pass to the ./configure command.
    # :skip_configure - skips the configure step
    #
    # === Block
    # You can also pass a block that if it returns true, it will not 
    # recompile.  So the general idea is return true if the exe is already
    # installed.
    def compile(url, temp_dir, options={})
      # TODO: Add invoke/revoke support using action(...), maybe 
      # make things run via Thor::Group
      
      installed = false
      if options[:bin_file]
        # Check if the bin file is installed
        installed = exec("which #{options[:bin_file]}", :log_stderr => false).strip != ''
      else
        raise "You must pass :bin_file or a block to compile" unless block_given?
        installed = yield()
      end
      
      if installed
        say_status :already_compiled, url, :blue
        return true
      else
        
        track_modification!
        # Compile and install
        Compile.new(self, url, temp_dir, options)
      end
    end
    
    class Compile
      attr_accessor :base
      attr_accessor :options
      
      # Sets up a compile object
      #
      # === Parameters
      # base<Thor>:: The main class
      # url<String>:: The url to download from
      # temp_dir<String>:: A path to a temporary directory where the compilation 
      # can take place
      def initialize(base, url, temp_dir, options)
        @base = base
        @temp_dir = temp_dir
        self.options = options
        @file = File.basename(url)
        @zip_file = @file[/[.]zip$/]
        @file_path = File.join(temp_dir, @file)
        
        # TODO: GET THE FIRST DIRECTORY INSTEAD
        dir_name = @file.gsub(/[.]tar[.]gz$/, '').gsub(/[.]zip$/, '')
        @extracted_path = File.join(temp_dir, dir_name)
        
        @base.say_status 'download and compile', url
        
        download(url)
        extract
        configure unless options[:skip_configure]
        make
        make_install
      end
      
      # Uses get to download the file and place it in the temp path
      def download(url)
        base.get(url, @file_path)
      end
      
      # Extract the compressed file
      def extract
        base.say_status 'extract', @file
        if @zip_file
          base.exec("cd #{@temp_dir} ; unzip #{@file}")
        else
          base.exec("cd #{@temp_dir} ; tar xvfpz #{@file}")
        end
      
        # Remove the file
        base.destination_files.rm_rf(@file_path)
      end
      
      # Takes a command and an action_name.  It says its running the action_name, then
      # runs the command and if there is non-zero exit status, it prints out an error,
      # stdout, and stderr, then raises an exception
      #
      # === Parameters
      # command<String>:: The command to be run
      # action_name<String>:: An action name (used to explain what is happening)
      def run_with_failure_handler(command, action_name)
        base.say_status action_name.downcase, ''
        stdout, stderr, exit_code, exit_status = base.exec(command, :with_codes => true)
        
        if exit_code != 0
          base.say_status :error, "Unable to #{action_name}, see output below", :red
          puts stdout
          puts stderr
          
          raise "Unable to configure #{action_name}"
        end
      end

      # Runs ./configure on the files
      def configure
        run_with_failure_handler("cd #{@extracted_path} ; ./configure #{options[:config_options] || ''}", 'configure')
      end
      
      # Runs make
      def make
        run_with_failure_handler("cd #{@extracted_path} ; make", 'make')
      end
      
      # Runs sudo make install
      def make_install
        run_with_failure_handler("cd #{@extracted_path} ; sudo make install", 'make install')
      end
      
    end
  end

end