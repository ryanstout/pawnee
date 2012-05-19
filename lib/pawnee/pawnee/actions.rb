module Pawnee
  module Actions
    
    def installed_version(package)
      packages = run("dpkg -l")
      
      
    end
    
    
    # Installs a package using the operating system's
    # package management system (currentl apt-get only)
    #
    #  install_package 'mysql-server5'
    #  install_package 'gcc', '4.5'
    #
    # === Parameters
    # package<String>:: The list of package to be installed
    # version<String>:: The version of the package
    def install_package(package, version=nil)
      package = "#{package}=#{version}" if version
      run "apt-get -y install #{package}"
    end
  end
end