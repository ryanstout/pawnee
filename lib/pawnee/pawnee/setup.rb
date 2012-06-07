require 'thor'

# Add setup to the base class
module Pawnee
  class Base < Thor
    if defined?(Rails)
      class Railtie < Rails::Railtie  
      end
    end

    def self.setup(gem_name)
      # Setup the railtie
      require "#{gem_name.gsub(/^pawnee[-]/, '')}/base"
      
      if defined?(Rails)
        Railtie.initializer "#{gem_name}.configure_rails_initialization" do
          gem_recipie_name = gem_name.gsub(/^pawnee[-]/, '')
          require "#{gem_recipie_name}/base"
        end
      end
    end
  end
end