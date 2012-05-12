# Add setup to the base class
module Pawnee
  class Base
    class Railtie < Rails::Railtie  
    end

    def self.setup(gem_name)
      # Setup the railtie
      
      puts "Setup: #{gem_name}"
      Railtie.initializer "#{gem_name}.configure_rails_initialization" do
        puts "PAWNEE NGINX----"
        gem_recipie_name = gem_name.gsub(/^pawnee[-]/, '')
        puts "Require: #{gem_recipie_name}/base"
        require "#{gem_recipie_name}/base"
      end
    end
  end
end