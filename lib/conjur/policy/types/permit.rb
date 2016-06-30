module Conjur
  module Policy
    module Types
      class Permit < Base
        attribute :role, kind: :member
        attribute :privilege, kind: :string, dsl_accessor: true
        attribute :resource, dsl_accessor: true
        attribute :replace, kind: :boolean, singular: true, dsl_accessor: true

        self.description = %(
Give permissions on a [Resource](#reference/resource) to a [Role](#reference/role). 

Once a privilege is given, permission checks performed by the role
will return `true`.

Note that permissions are not "inherited" in the same way that roles are.
If role A is granted to role B, then role B "inherits" all the privileges held 
by role A. If role A can `execute` a variable, then role B can as well.
The privileges on each resource are distinct, regardless of how they are named.
If role A has `execute` privilege on a resource called `dev`, the role does **not**
gain any privileges on a resource called `dev/password`. Role-based access control
is explicit in this way to avoid unintendend side-effects from the way that 
resources are named.
        
[More](/key_concepts/rbac.html) on role-based access control in Conjur.
        
See also: [Deny](#reference/deny)
)

        self.example = %(
- !variable answer
- !user deep_thought

- !permit
    role: !user deep_thought
    privileges: [ read, execute, update ]
    resource: !variable answer
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
