module Pawnee
  module Actions
    # Adds a :once option that will only do the action the first
    # time it is run (it will check for the text before it injects
    # it each time)
    def insert_into_file(destination, *args, &block)
      if block_given?
        data, config = block, args.shift
      else
        data, config = args.shift, args.shift
      end
      
      # Get the data if its a proc
      data = data.call if data.is_a?(Proc)
      
      if destination_files.binread(destination)[data]
        say_status :identical, destination
        # Don't run again, the text is already in place
        return
      end
      
      action Thor::Actions::InjectIntoFile.new(self, destination, data, config)
    end
    alias_method :inject_into_file, :insert_into_file
  end
end