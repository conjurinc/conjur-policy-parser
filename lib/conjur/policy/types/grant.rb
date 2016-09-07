module Conjur::Policy::Types
  class Grant < Base
    attribute :role, dsl_accessor: true
    attribute :member

    include RoleMemberDSL
    include AutomaticRoleDSL

    self.description = %(
Grant one role to another. When role A is granted to role B, 
then role B is said to "have" role A. The set of all memberships of role B
will include A. The set of direct members of role A will include role B.
    
If the role is granted with `admin` option, then the grantee (role B),
in addition to having the role, can also grant and revoke the role
to other roles.

The only limitation on role grants is that there cannot be any cycles
in the role graph. For example, if role A is granted to role B, then role B
cannot be granted to role A.

Users, groups, hosts, and layers can all behave as roles, which means they can be granted to and 
revoked from each other. For example, when a Group is granted to a User, 
the User gains all the privileges of the Group. (Note: "Adding" a User to 
a Group is just another way to say that the Group role is granted to the User).

Some `grant` operations have additional semantics beyond the role grant:
    
* When a Layer is granted to a Host, the automatic roles on the Layer are granted
    privileges on the Host. Specifically, the `observe` role is given `read` privilege,
    `use_host` is given `execute`, and `admin_host` is given `update`. The `admin`
    option is ignored.
)

    self.example = %(
- !user alice
  owner: !group security_admin

- !group operations
  owner: !group security_admin
    
- !group development
  owner: !group security_admin
  
- !group everyone
  owner: !group security_admin

- !grant
  role: !group operations
  member: !member
    role: !user alice
    admin: true

- !grant
  role: !group ops
  member: !group development

- !grant
  role: !group everyone
  member: !group development
  member: !group operations
)

    def to_s
      role_str   = if role.kind_of?(Array)
        role.join(', ')
      else
        role
      end
      member_str = if member.kind_of?(Array)
        member.map(&:role).join(', ')
      elsif member 
        member.role
      end
      admin = Array(member).map do |member|
        member && member.admin
      end
      admin_str = if Array(member).count == admin.select{|admin| admin}.count
        " with admin option"
      elsif admin.any?
        " with admin options: #{admin.join(', ')}"
      end
      %Q(Grant #{role_str} to #{member_str}#{admin_str})
    end
  end
end
