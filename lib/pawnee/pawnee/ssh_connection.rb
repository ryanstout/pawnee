module Pawnee
  module SshConnection
    # Reconnects to the remote server (using net/ssh).
    # This is useful since often things in linux don't take effect
    # until the user creates a new login shell (adding a user to
    # a group for example)
    def reconnect!
      host = self.destination_connection.host
      options = self.destination_connection.options
      user = options[:user]
      
      # Close the existing connection
      self.destination_connection.close
      
      # Reconnect
      new_connection = Net::SSH.start(host, user, options)
      
      # Copy the instance variables to the old conection so we can keep using
      # the same session without reassigning references
      self.destination_connection.instance_variables.each do |variable_name|
        value = new_connection.instance_variable_get(variable_name)
        self.destination_connection.instance_variable_set(variable_name, value)
      end
    end
  end
end