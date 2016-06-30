module Conjur::Policy::Types
  class Update < Base
    attribute :record

    self.description = %(
Make explicit changes to an existing record's attributes and/or annotations.

For example, you can change annotations on a [Resource](#reference/resource), or the `uidnumber` of a [User](#reference/user).
    
Generally, Update is not used explicitly. Instead, an update is performed by the create-or-replace behavior of
statements such as User, Group, Host, Layer, etc.
)

    self.example = %(
- !user wizard
    annotations:
      color: gray

- !update
    record: !user wizard
      annotations:
        color: white
)
    
    def to_s
      messages = [ "Update #{record}" ]
      (record.custom_attribute_names||[]).each do |k|
        messages.push "  Set field '#{k}'" 
      end
      (record.annotations||{}).each do |k,v|
        messages.push "  Set annotation '#{k}'"
      end
      messages.join("\n")
    end
  end
end
