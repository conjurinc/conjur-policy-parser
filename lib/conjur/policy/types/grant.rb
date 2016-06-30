module Conjur::Policy::Types
  class Grant < Base
    attribute :role, dsl_accessor: true
    attribute :member
    attribute :replace, kind: :boolean, singular: true, dsl_accessor: true

    include RoleMemberDSL
    include AutomaticRoleDSL

    self.description = %(
Grant one [Role](#reference/role) to another. When role A is granted to role B, 
then role B is said to "have" role A. The set of all memberships of role B
will include A. The set of direct members of role A will include role B.
    
If the role is granted with `admin` option, then the grantee (role B),
in addition to having the role, can also grant and revoke the role
to other roles.

The only limitation on role grants is that there may never be a cycle 
in the role graph. For example, if role A is granted to role B, then role B
cannot be granted to role A.

Several types of Conjur records are roles. For example, Users, Groups,
Hosts and Layers are all roles. This means they can be granted to and 
revoked from each other. For example, when a Group is granted to a User, 
the User gains all the privileges of the Group. (Note: "Adding" a User to 
a Group is just another way to say that the Group role is granted to the User).

Some `grant` operations have additional semantics beyond the role grant:
    
* When a Layer is granted to a Host, the automatic roles on the Layer are granted
    privileges on the Host. Specifically, the `observe` role is given `read` privilege,
    `use_host` is given `execute`, and `admin_host` is given `update`. The `admin`
    option is ignored.

[More](/key_concepts/rbac.html) on role-based access control in Conjur.
    
See also: [Permit](#reference/permit) for [Resources](#reference/resource)
)

    self.example = %(
- !user Link
- !user Navi

- !grant
    role: !user Navi
    member: !user Link
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
      %Q(Grant #{role_str} to #{member_str}#{replace ? ' with replacement ' : ''}#{admin_str})
    end
  end
end
