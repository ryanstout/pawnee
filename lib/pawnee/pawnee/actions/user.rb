require 'pawnee/actions/base_model'

module Pawnee
  module Actions
    # Adds the user (specified by login) to the group
    def add_user_to_group(login, group)
      user = self.user(login)
      user.groups << group
      user.groups = user.groups.sort.uniq
      user.save
    end
    
    # Return the user object for the login
    def user(login)
      return User.new(self, {:login => login})
    end
    
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
      define_attribute_methods [:login, :uid, :gid, :groups, :comment, :shell, :password, :home]
      change_attr_accessor [:login, :uid, :gid, :groups, :comment, :shell, :password, :home]

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
      
      def passwd_data(find_user)
        passwd_data = base.destination_files.binread('/etc/passwd')

        if passwd_data
          passwd_data.split(/\n/).each do |line|
            user, *_, home, shell = line.split(':')
          
            if user == find_user
              return home, shell
            end
          end
        end
        
        return nil, nil        
      end
      
      def home_for_user(find_user)
        home, shell = passwd_data(find_user)
        return home
      end

      def shell_for_user(find_user)
        home, shell = passwd_data(find_user)
        return shell
      end
      
      # Pull in the current (starting) state of the attributes 
      # for the User model
      def read_from_system
        @uid, stderr, exit_code, _ = exec("id -u #{login}", :with_codes => true, :log_stderr => false, :no_pty => true)
        @uid = @uid.strip
        if exit_code == 0
          # The login exists, load in more data
          @gid = exec("id -g #{login}", :log_stderr => false, :no_pty => true).strip
          
          @groups = exec("groups #{login}", :no_pty => true).gsub(/^[^:]+[:]/, '').strip.split(/ /).sort
          @home = home_for_user(login)
          
          # TODO: Load in existing shell
          @shell = shell_for_user(login)
          self.new_record = false

          # Reject any ones we just changed, so its as if we did a find with these
          @changed_attributes = @changed_attributes.reject {|k,v| [:uid, :gid, :groups, :login].include?(k.to_sym) }
          @original_groups_value = @groups
        else
          # No user
          @uid = nil
          @groups ||= []
          @shell ||= '/bin/bash'
          self.shell_will_change!
          self.new_record = true
        end
      end

      # Write any changes out
      def save
        # Since groups is an array, we have to manually check to see if
        # its changed, because people can do << to it
        if @original_groups_value != @groups
          # Mark as changed
          self.groups_will_change!
          
          @original_groups_value = @groups
        end
        
        if changed?
          raise "A login must be specified" unless login
          
          if new_record?
            # Just create a new user
            command = ["useradd"]
            base.say_status :create_user, login, :green
          else
            # Modify an existing user
            command = ["usermod"]
            base.say_status :update_user, login, :green
          end
          
          # Set options
          command << "-u #{uid}" if uid && uid_changed?
          command << "-g #{gid}" if gid && gid_changed?
          command << "-G #{groups.join(',')}" if groups && groups_changed? && groups.size != 0
          command << "-c #{comment.inspect}" if comment && comment_changed?
          command << "-s #{shell.inspect}" if shell && shell_changed?
          command << "-p #{password.inspect}" if password && password_changed?
          
          # TODO: If update, we need to make the directory first to move things to
          command << "-m -d #{home.inspect}" if home && home_changed?
          command << login
          
          base.as_root do
            base.exec(command.join(' '), :no_pty => true)
          end
        else
          base.say_status :user_exists, login, :blue
        end
      end
      
      def destroy
        self.new_record = true
        base.as_root do
          base.exec("userdel #{login}", :no_pty => true)
        end
      end
    end
  end
end