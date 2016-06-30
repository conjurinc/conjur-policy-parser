module Conjur::Policy::Types
  class Deny < Base

    self.description = %(
Deny privilege(s) on a [Resource](#reference/resource) to a role.
Once a privilege is denied, permission checks performed by the role
will return `false`.

If the role does not hold the privilege, this statement is a nop.

See also: [Revoke](#reference/revoke) for [Roles](#reference/role)
)

    self.example = %(
- !variable secret
- !user rando
- !deny
    role: !user rando
    privilege: read
    resource: !variable secret
)

    attribute :role, kind: :role, dsl_accessor: true
    attribute :privilege, kind: :string, dsl_accessor: true
    attribute :resource, dsl_accessor: true
        
    include ResourceMemberDSL

    def to_s
      "Deny #{role} to '#{privilege}' #{resource}"
    end
  end
end
