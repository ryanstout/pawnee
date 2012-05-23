module Pawnee
  module Actions
    class User
      # uid, gid - might need to be assigned sometimes?
      
      attr_reader :base
      attr_reader :user
      
      def initialize(base, user)
        @base = base
        @user = user
      end

      def uid
        exec("id -u #{user}")
      end
      
      def gid
        exec("id -g #{user}")
      end

      def groups
        # List all of the groups
        exec("group #{user}")
      end
      
      def comment
      end
      
      def shell
      end
      
      def password
      end
      
      def groups=(groups)
      end
      
    end
  end
end