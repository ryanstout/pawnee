module Pawnee
  module Invocation
    # This is copied in from thor/invocation.rb#initialize, 
    # we can't extend from a module, so we just move this setup
    # to a method
    def pawnee_setup_invocations(args=[], options={}, config={}) #:nodoc:
      # TODO: This may be also called as Thor::Invocation since we're calling
      # super in the main initialize
      @_invocations = config[:invocations] || Hash.new { |h,k| h[k] = [] }
      @_initializer = [ args, options, config ]
    end

  end
end