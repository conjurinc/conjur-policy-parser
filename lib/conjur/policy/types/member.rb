module Conjur::Policy::Types
  class Member < Base
    def initialize role = nil
      self.role = role
    end

    attribute :role
    attribute :admin, kind: :boolean, singular: true

    self.description = %(
Designate the members of a [Role](#reference/role) such as a [Group](#reference/group).
    
The member indicates the "grantee" (which role will gain the role grant), as well as the
`admin` option which determines whether the grantee can grant/revoke the role to other roles.

The default value for `admin` is `false`.
)

    self.example = %(
- !user dee
- !user dum
- !group brothers

- !grant
  role: !group brothers
  members:
  - !user dee
  - !member dum
      role: !user dum
      admin: true
)

    def to_s
      "#{role} #{admin ? 'with' : 'without'} admin option"
    end
  end
end
