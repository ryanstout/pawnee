require 'active_model'

module Pawnee
  module Actions
    def create_user(attributes)
      User.new(self, attributes)
    end
    
    
    
    # The user class handles creating, updating, and deleting users.  Users are tied to the
    # login attribute and all other attributes will update based on that login.
    #
    # === Passwords
    # Instead of putting passwords in code, you should either:
    # 
    # 1) not use a password (which is fine for system users)
    # or
    # 2) Set the password value to an encryped password.  You can generated an encryped password
    # with the following ruby command:
    # 
    #   ruby -e "puts 'password'.crypt('passphrase')"
    #
    #
    class User
      include ActiveModel::Dirty

      define_attribute_methods [:login, :uid, :gid, :groups, :comment, :shell, :password]

      attr_accessor :base
      attr_accessor :new_record
      
      def new_record?
        !!@new_record
      end

      def update_attributes(attributes)
        attributes.each_pair do |key,value|
          self.send(:"#{key}=", value) if self.respond_to?(:"#{key}=")
        end
      end
      
      def initialize(base, attributes)
        @base = base
        
        if attributes[:login]
          # Read the current attributes from the system
          read_from_system()
        end
        
        # Set the attributes, track what changed
        update_attributes(attributes)
      end
      
      # Pull in the current (starting) state of the attributes 
      # for the User model
      def read_from_system
        @uid, _, exit_code, _ = exec("id -u #{login}", true)
        if exit_code == 0
          # The login exists, load in more data
          @gid = exec("id -g #{login}")
          @groups = exec("groups #{login}").gsub(/^[^:]+[:]/, '').strip.split(/ /)
          self.new_record = false
        else
          # No user
          @uid = nil
          self.new_record = true
        end
      end

      # Write any changes out
      def save
        if changed?
          if new_record?
            # Just create a new user
            command = ["useradd"]
          else
            # Modify an existing user
            command = ["usermod"]
          end
          
          # Set options
          command << "-u #{uid}" if uid && uid_changed?
          command << "-g #{gid}" if gid && gid_changed?
          command << "-G #{groups.join(',')}" if groups && groups_changed?
          command << "-c \"#{comment.inspect}\"" if comment && comment_changed?
          command << "-s \"#{shell.inspect}\"" if shell && shell_changed?
          command << "-p \"#{password.inspect}\"" if password && password_changed?
          command << login

          run(command.join(' '))
        end
      end
      
      def destroy
        self.new_record = true
        run("userdel #{login}")
      end
    end
  end
end