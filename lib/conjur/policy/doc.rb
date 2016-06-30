module Conjur
  module Policy
    module Doc
      Attribute = Struct.new(:id, :kind)

      Operation = Struct.new(:id, :super_id, :description, :example, :attributes)
      
      class << self
        def list
          all_types = Set.new
          new_types = Set.new
          new_types += Conjur::Policy::Types::Base.subclasses
          all_types += new_types
          while !new_types.empty?
            iteration_new_types = Set.new
            new_types.each do |type|
              subtypes = type.subclasses
              iteration_new_types += (Set.new(subtypes) - all_types)
              all_types += subtypes
            end
            new_types = iteration_new_types.dup
            iteration_new_types.clear
          end
          all_types.map do |type|
            # TODO: I am not sure what this is
            next if type == Conjur::Policy::Ruby::Policy

            description = type.send(:description) rescue ""
            example = type.send(:example) rescue ""
            attributes = type.fields.map do |id, kind|
              Attribute.new(id, kind)
            end
            unless attributes.empty?
              super_id = type.superclass.short_name rescue nil
              super_id = nil if super_id == "Base"
              Operation.new(type.short_name, super_id, description, example, attributes)
            end
          end.compact.sort{|a,b| a.id <=> b.id}
        end
      end
    end
  end
end
