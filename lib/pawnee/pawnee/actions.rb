require 'pawnee/actions/package'
require 'pawnee/actions/compile'
require 'pawnee/actions/user'
require 'pawnee/actions/inject_into_file'

module Pawnee
  # The pawnee gem provides the Pawnee::Base class which includes Thor::Actions,
  # ThorSsh::Actions.  Pawnee::Base also adds in its own actions from the pawnee
  # gem
  module Actions
    # This is copied in from thor/actions.rb#initialize, 
    # we can't extend from a module, so we just move this setup
    # to a method
    def pawnee_setup_actions(args=[], options={}, config={}) #:nodoc:
      self.behavior = case config[:behavior].to_s
        when "force", "skip"
          _cleanup_options_and_set(options, config[:behavior])
          :invoke
        when "revoke"
          :revoke
        else
          :invoke
      end
      
      yield
      self.destination_root = config[:destination_root]
    end
  end
end
    