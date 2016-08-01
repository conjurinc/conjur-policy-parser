module Conjur
  module Policy
    module Types
      class Permit < Base
        attribute :role, kind: :member
        attribute :privilege, kind: :string, dsl_accessor: true
        attribute :resource, dsl_accessor: true
        attribute :replace, kind: :boolean, singular: true, dsl_accessor: true

        self.description = %(
Give privileges on a resource to a role.

Once a privilege is given, permission checks performed by the role
will return `true`.

Note that permissions are not "inherited" by any mechanism such as glob 
expressions on resource ids; each privilege must be 
explicitly given on each resource. Inheritance of privileges only happens through
role grants. Role-based access control
is explicit in this way to avoid unintendend side-effects from the way that 
resources are named.
)

        self.example = %(
- !layer prod/app
        
- !variable prod/database/password
        
- !permit
  role: !layer prod/app
  privileges: [ read, execute ]
  resource: !variable prod/database/password
)
        
        include ResourceMemberDSL
        
        def initialize privilege = nil
          self.privilege = privilege
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
