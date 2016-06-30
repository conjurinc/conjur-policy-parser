module Conjur
  module Policy
    module Types
      class Retire < Base
        attribute :record, kind: :resource

        self.description = %(
Move a Role or Resource to the attic.

When you no longer need a role or resource in Conjur, you `retire` it.
This is different than deleting it. When you retire an item, all of
its memberships and privileges are revoked and its ownership is
transferred to the `attic` user. This is a special user in Conjur that
is created when you first bootstrap your Conjur endpoint. By
retiring rather than deleting items, the integrity of the immutable
audit log is preserved.

You can unretire items by logging in as the
'attic' user and transferring their ownership to another role. The
'attic' user's API key is stored as a variable in Conjur at
`conjur/users/attic/api-key`. It is owned by the 'security_admin'
group. )

        self.example = %(
- !retire
    record: !user DoubleOhSeven
)

        def to_s
          "Retire #{record}"
        end
      end
    end
  end
end

