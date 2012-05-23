module Pawnee
  module Actions
    
    # Returns true if the package is installed.  If a version is 
    # listed, it will make sure it matches the version.
    #
    #  package_installed? 'memcached'
    #  -> true
    #
    #  package_installed? 'memcached', '1.4.7-0.1ubuntu1'
    #  -> false
    #
    # === Parameters
    # package_name<String>:: The name of package
    def package_installed?(package_name, version=nil)
      installed_version = installed_package_version(package_name)
      if version
        return (installed_version == version)
      else
        return !!installed_version
      end
    end
    
    # Returns the version of a package that is installed
    #
    #  installed_package_version 'memcached'
    #  -> 1.4.7-0.1ubuntu1
    #
    # === Parameters
    # package_name<String>:: The name of package
    def installed_package_version(package_name)
      packages = exec("sudo dpkg -l")
      
      packages.split(/\n/).grep(/^ii /).each do |package|
        _, name, version = package.split(/\s+/)
        
        if name == package_name
          return version
        end
      end
      
      return nil
    end
    
    # Installs a package using the operating system's
    # package management system (currentl apt-get only)
    #
    #  install_package 'mysql-server5'
    #  install_package 'gcc', '4.5'
    #
    # === Parameters
    # package_name<String>:: The name of package to be installed
    # version<String>:: The version of the package
    def install_package(package_name, version=nil)
      if package_installed?(package_name)
        say_status "package already installed", package_name
      else
        package_name = "#{package_name}=#{version}" if version
        exec("sudo apt-get -y install #{package_name}")
        say_status "installed package", package_name.gsub('=', ' ')
      end
    end
    
    # Removes package_name
    #
    # === Parameters
    # package_name<String>:: The name of package
    def remove_package(package_name)
      if package_installed?(package_name)
        say_status "removed package", package_name
        exec("sudo apt-get -y remove #{package_name}")
      else
        say_status "package not removed", package_name
      end
    end
  end
end