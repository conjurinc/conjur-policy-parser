module Conjur
  module PolicyParser
    module Types
      class Permit < Base
        attribute :role
        attribute :privilege, kind: :string, dsl_accessor: true
        attribute :resource, dsl_accessor: true

        include ResourceMemberDSL
        
        def initialize privilege = nil
          self.privilege = privilege
        end

        def subject_id
          resource.id
        end
        
        def to_s
          if Array === role
            role_string = role.map &:role
            admin = false
          else
            role_string = role.role
            admin = role.admin
          end
          "Permit #{role_string} to [#{Array(privilege).join(', ')}] on #{Array(resource).join(', ')}#{admin ? ' with grant option' : ''}"
        end
      end
    end
  end
end
