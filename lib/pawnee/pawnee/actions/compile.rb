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
      
      # Download the file
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
      
      def run_with_failure_handler(command, action_name)
        base.say_status action_name.downcase, ''
        stdout, stderr, exit_code, exit_status = base.exec(command, true)
        
        if exit_code != 0
          base.say_status :error, "Unable to #{action_name}, see output below", :red
          puts stdout
          puts stderr
          
          raise 'Unable to configure'
        end
      end

      def configure
        run_with_failure_handler("cd #{@extracted_path} ; ./configure", 'configure')
      end
      
      def make
        run_with_failure_handler("cd #{@extracted_path} ; make", 'make')
      end
      
      def make_install
        run_with_failure_handler("cd #{@extracted_path} ; sudo make install", 'make install')
      end
      
    end
  end

end