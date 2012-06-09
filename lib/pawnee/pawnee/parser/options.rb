
module Pawnee
  class Options < Thor::Options

    # Add the config options in as defaults first
    def initialize(hash_options={}, defaults={})
      # TODO: Add options to flatten from yaml
      Pawnee::Base.config_options.each_pair do |key,value|
        unless defaults[key]
          defaults[key] = value
        end
      end
      
      super(hash_options, defaults)
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