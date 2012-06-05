require 'pawnee/actions/base_model'

module Pawnee
  module Actions
    def create_user(attributes)
      User.new(self, attributes).save
    end
    
    def delete_user(login)
      User.new(self, {:login => login}).destroy
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
    class User < BaseModel
      define_attribute_methods [:login, :uid, :gid, :groups, :comment, :shell, :password]
      change_attr_accessor [:login, :uid, :gid, :groups, :comment, :shell, :password]

      attr_accessor :base
      
      def initialize(base, attributes)
        @base = base
        
        if attributes[:login]
          self.login = attributes[:login]
          # Read the current attributes from the system
          read_from_system()
        end
        
        # Set the attributes, track what changed
        update_attributes(attributes)
      end
      
      def exec(*args)
        return base.exec(*args)
      end
      
      def run(*args)
        return base.run(*args)
      end
      
      # Pull in the current (starting) state of the attributes 
      # for the User model
      def read_from_system
        @uid, stderr, exit_code, _ = exec("id -u #{login}", true)
        @uid = @uid.strip
        if exit_code == 0
          # The login exists, load in more data
          @gid = exec("id -g #{login}").strip
          @groups = exec("groups #{login}").gsub(/^[^:]+[:]/, '').strip.split(/ /)
          self.new_record = false

          # Reject any ones we just changed, so its as if we did a find with these
          @changed_attributes = @changed_attributes.reject {|k,v| [:uid, :gid, :groups, :login].include?(k.to_sym) }
        else
          # No user
          @uid = nil
          self.new_record = true
        end
      end

      # Write any changes out
      def save
        if changed?
          raise "A login must be specified" unless login
          
          if new_record?
            # Just create a new user
            command = ["useradd"]
            base.say_status :create_user, login
          else
            # Modify an existing user
            command = ["usermod"]
            base.say_status :update_user, login
          end
          
          # Set options
          command << "-u #{uid}" if uid && uid_changed?
          command << "-g #{gid}" if gid && gid_changed?
          command << "-G #{groups.join(',')}" if groups && groups_changed?
          command << "-c #{comment.inspect}" if comment && comment_changed?
          command << "-s #{shell.inspect}" if shell && shell_changed?
          command << "-p #{password.inspect}" if password && password_changed?
          command << login
          
          base.as_root do
            base.exec(command.join(' '))
          end
        else
          base.say_status :user_exists, login, :blue
        end
      end
      
      def destroy
        self.new_record = true
        base.as_root do
          base.exec("userdel #{login}")
        end
      end
    end
  end
end