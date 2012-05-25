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
    def compile(url, temp_dir)
      Compile.new(self, url, temp_dir)
    end
    
    class Compile
      attr_accessor :base
      
      # Sets up a compile object
      #
      # === Parameters
      # base<Thor>:: The main class
      # url<String>:: The url to download from
      # temp_dir<String>:: A path to a temporary directory where the compilation 
      # can take place
      def initialize(base, url, temp_dir)
        @base = base
        @temp_dir = temp_dir
        @file = File.basename(url)
        @zip_file = @file[/[.]zip$/]
        @file_path = File.join(temp_dir, @file)
        
        # TODO: GET THE FIRST DIRECTORY INSTEAD
        dir_name = @file.gsub(/[.]tar[.]gz$/, '').gsub(/[.]zip$/, '')
        @extracted_path = File.join(temp_dir, dir_name)
        
        @base.say_status 'download and compile', url
        
        download(url)
        extract
        configure
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
        stdout, stderr, exit_code, exit_status = base.exec(command, true)
        
        if exit_code != 0
          base.say_status :error, "Unable to #{action_name}, see output below", :red
          puts stdout
          puts stderr
          
          raise "Unable to configure #{action_name}"
        end
      end

      # Runs ./configure on the files
      def configure
        run_with_failure_handler("cd #{@extracted_path} ; ./configure", 'configure')
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