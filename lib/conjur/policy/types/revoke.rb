module Conjur
  module Policy
    module Types
      class Revoke < Base
        attribute :role, dsl_accessor: true
        attribute :member, kind: :role, dsl_accessor: true

        self.description = %(
Remove a [Role](#reference/role) grant. (contrast: [Grant](#reference/grant))

Some `revoke` operations have additional semantics beyond the role revocation:
        
* When a Layer is revoked from a Host, the automatic roles on the Layer are denied their
    privileges on the Host. Specifically, the `observe` role is denied `read` privilege,
    `use_host` is denied `execute`, and `admin_host` is denied `update`.

See also: [role-based access control guide](/key_concepts/rbac.html).
)

        self.example = %(
- !revoke
    role: !group soup_eaters
    member: !user you
)

        def to_s
          "Revoke #{role} from #{member}"
        end
      end
    end
  end
end
