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
      
      if config[:once]
        if destination_files.binread(destination)[data]
          # Don't run again, the text is already in place
          return
        end
      end
      
      action InjectIntoFile.new(self, destination, data, config)
    end
  end
end