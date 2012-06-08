module Pawnee
  class Base
    module Roles
      def self.included(base) #:nodoc:
        base.extend ClassMethods
      end
      
      module ClassMethods
        # Assigns the role for this class
        def role(role_name)
          @role = role_name
        end

        def class_role
          @role.to_s
        end      

        # Returns the recipe classes in order based on the Gemfile order
        def ordered_recipes
          return @ordered_recipes if @ordered_recipes
          names = Bundler.load.dependencies.map(&:name)

          # Setup a hash with the recipe name and the recipe class
          recipe_pool = recipes.dup.inject({}) {|memo,recipe| memo[recipe.gem_name] = recipe ; memo }

          # Go through the gems in the order they are in the Gemfile, then
          # add them to the ordered list
          @ordered_recipes = []
          names.each do |name|
            if recipe_pool[name]
              @ordered_recipes << recipe_pool[name]
              recipe_pool.delete(name)
            end
          end

          # Add the remaining recipes (load them after everything else)
          @ordered_recipes += recipe_pool.values

          return @ordered_recipes
        end

        # Returns the list of classes that match the current list of roles
        # in the correct run order
        def recipe_classes_with_roles(roles)
          # Check to make sure some recipes have been added
          if ordered_recipes.size == 0
            raise Thor::InvocationError, 'no recipes have been defined'
          end
          if (roles.is_a?(Array) && roles.size == 0) || roles == :all
            # Use all classes
            role_classes = ordered_recipes
          else
            # Remove classes that don't fit the roles being used
            role_classes = ordered_recipes.reject do |recipe_class|
              ![roles].flatten.map(&:to_s).include?(recipe_class.class_role)
            end
          end        
        end

        # Invokes all recipes that implement the passed in role
        def invoke_roles(task_name, roles, options={})   
          role_classes = self.recipe_classes_with_roles(roles)

          # Run the taks on each role class
          role_classes.each do |recipe_class|
            # This class matches the role, so we should run it
            recipe = recipe_class.new([], options)

            servers = options[:servers] || options['servers']
            
            unless servers
              # No servers, just run locally
              recipe.setup()
            else
              # Run the setup task, setting up the needed connections
              servers.each do |server|
                # Only run on this server if the server supports the current recipe's
                # role.
                next unless server.is_a?(String) || server['roles'].include?(recipe_class.class_role)

                # Set the server for this call
                recipe.server = server.is_a?(String) ? server : server['domain']

                # Run the invoked task
                recipe.send(task_name.to_sym)

                # Remove the server
                recipe.server = nil

                # Copy back any updated options
                options = recipe.options

                # Close the connection
                if recipe.destination_connection
                  recipe.destination_connection.close
                  recipe.destination_connection = nil
                end
              end
            end
          end
        end
      end
    end
  end
end