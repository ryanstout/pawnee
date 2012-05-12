# This railtie is for bootstrapping the pawnee gem only
# It adds the config/pawnee directory to the loadpath
if defined?(Rails)
  module Pawnee
    class Railtie < Rails::Railtie
      initializer "pawnee.configure_rails_initialization" do
        puts "INITIALIZE1"
      
        path = (Rails.root + 'config/pawnee').to_s
        puts path
        unless $LOAD_PATH.include?(path)
          $LOAD_PATH.unshift(path)
        end
      
        puts "Require: pawnee/base"
        require 'pawnee/base'

      end
    end
  end
else
  require 'pawnee/base'
end