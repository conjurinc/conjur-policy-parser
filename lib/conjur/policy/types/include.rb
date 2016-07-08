module Conjur::Policy::Types
  # Include another policy into the policy.
  class Include < Base
    attribute :file, kind: :string, type: String, singular: true, dsl_accessor: true

    self.description = %(
Includes the contents of another policy file.

By using this feature, policies for an entire organization can be
defined in one source repository, and then unified by a top-level
"Conjurfile".

Attributes:

* **file** path to the included policy file, relative to the including policy file.
    This is the default attribute, so it can be specified in shorthand form as:
    `- !include the-policy.yml`

Included policies inherit the namespace and owner of the enclosing
context. To include a policy with a different namespace and owner,
first define an enclosing policy record with the following attributes:
    
* **id** the name which is appended to the current namespace
* **owner** the desired owner
    
Then, within the body of that policy, include the additional 
policy files.
)

    self.example = %(
- !include groups.yml
    
- !policy
  id: ops
  owner: !group operations
  body:
  - !include jenkins-master.yml
  - !include ansible.yml
  - !include openvpn.yml
)
    
    def id= value
      self.file = value
    end
  end
end
