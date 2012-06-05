require 'active_model'

module Pawnee
  module Actions
    
    class BaseModel
      include ActiveModel::Dirty
      attr_accessor :new_record
      
      def new_record?
        !!@new_record
      end

      def update_attributes(attributes)
        attributes.each_pair do |key,value|
          self.send(:"#{key}=", value) if self.respond_to?(:"#{key}=")
        end
      end
      
      def self.change_attr_accessor(method_names)
        [method_names].flatten.each do |method_name|
          self.send(:define_method, :"#{method_name}") do
            return instance_variable_get("@#{method_name}")
          end
          
          self.send(:define_method, :"#{method_name}=") do |val|
            self.send(:"#{method_name}_will_change!") unless val == instance_variable_get("@#{method_name}")
            instance_variable_set("@#{method_name}", val)
          end
        end
      end
    end
    
  end
end