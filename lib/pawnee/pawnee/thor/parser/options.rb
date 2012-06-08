class Thor
  class Options
    # Add the config options in as defaults first
    def initialize(hash_options={}, defaults={})
      # TODO: Add options to flatten from yaml
      # defaults = Pawnee::Base.config_options.merge(defaults)
      Pawnee::Base.config_options.each_pair do |key,value|
        unless defaults[key]
          defaults[key] = value
        end
      end
      
      options = hash_options.values
      
      super(options)
      
      # Add defaults
      defaults.each do |key, value|
        @assigns[key.to_s] = value
        @non_assigned_required.delete(hash_options[key])
      end
      
      # Don't require server here, since it can come from servers
      @non_assigned_required.delete(hash_options[:server])
      
      @shorts, @switches, @extra = {}, {}, []
      
      options.each do |option|
        @switches[option.switch_name] = option
      
        option.aliases.each do |short|
          @shorts[short.to_s] ||= option.switch_name
        end
      end
    end

    # Change the option parsing so it does not freeze the hash
    def parse(args)
      @pile = args.dup

      while peek
        match, is_switch = current_is_switch?
        shifted = shift

        if is_switch
          case shifted
            when SHORT_SQ_RE
              unshift($1.split('').map { |f| "-#{f}" })
              next
            when EQ_RE, SHORT_NUM
              unshift($2)
              switch = $1
            when LONG_RE, SHORT_RE
              switch = $1
          end

          switch = normalize_switch(switch)
          option = switch_option(switch)
          @assigns[option.human_name] = parse_peek(switch, option)
        elsif match
          @extra << shifted
          @extra << shift while peek && peek !~ /^-/
        else
          @extra << shifted
        end
      end

      check_requirement!

      assigns = Thor::CoreExt::HashWithIndifferentAccess.new(@assigns)
      # assigns.freeze
      assigns
    end
    
  end
end