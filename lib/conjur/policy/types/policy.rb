module Conjur
  module Policy
    module Types
      class YAMLList < Array
        def tag
          [ "!", self.class.name.split("::")[-1].underscore ].join
        end

        def encode_with coder
          coder.represent_seq tag, self
        end
      end

      module Tagless
        def tag; nil; end
      end

      module CustomStatement
        def custom_statement handler, &block
          record = yield
          class << record
            include RecordReferenceFactory
          end
          push record
          do_scope record, &handler
        end
      end

      module Grants
        include CustomStatement

        def grant &block
          custom_statement(block) do
            Conjur::Policy::Types::Grant.new
          end
        end

        def revoke &block
          custom_statement(block) do
            Conjur::Policy::Types::Revoke.new
          end
        end
      end

      module Permissions
        include CustomStatement

        def permit privilege, &block
          custom_statement(block) do
            Conjur::Policy::Types::Permit.new(privilege)
          end
        end

        def give &block
          custom_statement(block) do
            Conjur::Policy::Types::Give.new
          end
        end

        def retire &block
          custom_statement(block) do
            Conjur::Policy::Types::Retire.new
          end
        end
      end

      # Entitlements will allow creation of any record, as well as declaration
      # of permit, deny, grant and revoke.
      class Entitlements < YAMLList
        include Tagless
        include Grants
        include Permissions

        def policy id=nil, &block
          policy = Policy.new
          policy.id(id) unless id.nil?
          push policy

          do_scope policy, &block
        end
      end

      class Body < YAMLList
        include Grants
        include Permissions
      end

      # Policy includes the functionality of Entitlements, wrapped in a
      # policy role, policy resource, policy id and policy version.
      class Policy < Record
        include ActsAsResource
        include ActsAsRole

        self.description = %(
Create a policy. A policy is composed of the following:
        
* **id** A unique id, which can be prefixed by a `namespace`.
* **body** A set of records such as variables, groups and layers which are "owned" by the policy.
        
Under the hood, a Policy is actually a role *and* a resource.
The role is a role whose kind is "policy", and it has the specified `id`. By default
the policy role is granted, with `admin` option, to the `--as-group` or `--as-role` option which is specified
when the policy is loaded. The policy resource is a resource whose kind is "policy", and
whose owner is the policy role.
        
All the records declared in the `body` of the policy are also owned by the policy role
by default. As a result, the role specified by `--as-group` or `--as-role` has full
ownership and management of everything defined in the policy.

Policies should be self-contained; they should not generally make any reference to 
records from outside the policy. This way, the policy can be loaded with different
`--as-group`, `--as-role`, and `--namespace` options to serve different functions in the workflow.
For example, if a policy is loaded into the `dev` namespace with `--as-group dev-admin`, 
then a "dev" version of the policy is created with full management assigned to the `dev-admin` group.

[See above](#example) for an example of a complete policy.
)

        self.example = %(
- !policy
    id: example/v1
    body:
    - &secrets
      - !variable secret
        
    - !layer
        
    - !grant
        role: !layer
        permissions: [ read, execute ]
        resources: *secrets
)

        def role
          raise "account is nil" unless account
          @role ||= Role.new("#{account}:policy:#{id}").tap do |role|
            role.owner = Role.new(owner.roleid)
          end
        end

        def resource
          raise "account is nil" unless account
          @resource ||= Resource.new("#{account}:policy:#{id}").tap do |resource|
            resource.owner = Role.new(role.roleid)
          end
        end

        # Body is handled specially.
        def referenced_records
          super - Array(@body)
        end

        def body &block
          if block_given?
            singleton :body, lambda { Body.new }, &block
          end
          @body
        end

        def body= body
          @body = body
        end

        protected

        def singleton id, factory, &block
          object = instance_variable_get("@#{id}")
          unless object
            object = factory.call
            class << object
              include Tagless
            end
            instance_variable_set("@#{id}", object)
          end
          do_scope object, &block
        end
      end
    end
  end
end
