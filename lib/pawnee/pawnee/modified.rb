module Pawnee
  module Modified
    def self.included(base)
      # Extend EmptyDirectory to track modifiations
      Thor::Actions::EmptyDirectory.class_eval do
        alias :old_invoke_with_conflict_check :invoke_with_conflict_check
        
        # Change invoke with conflict check to track changes
        # when the block is invoked.
        def invoke_with_conflict_check(*args, &block)
          if block_given?
            old_invoke_with_conflict_check(*args) do
              results = yield
              base.track_modification!
              return results
            end
          else
            return old_invoke_with_conflict_check(*args)
          end
        end
      end
    end
    
    
    # Actions track if they modify something, or if it is
    # already in the desired state.  If they modify, they
    # call the track_modification! method on the base class.
    #
    # modified? returns true if there has been a tracked
    # modification within the current modify_block block
    # or within the current task.
    def modified?
      (@modifications && @modifications.first) || false
    end
    
    # Track a modification within the current modification 
    # block.  
    def track_modification!
      @modifications ||= [false]
      @modifications[@modifications.size-1] = true
    end
    
    # Allows you to track modifications within a block.  During
    # the block any call to modified? will return the value for
    # only during the block.
    def modify_block(&block)
      @modifications ||= [false]
      
      # Add a modification value to the stack
      @modifications << false
      
      yield
      
      # Return the modification value (can also be retrieved
      # with modified?)
      return @modifications.pop
    end
  end
end