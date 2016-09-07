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
A policy is used to collect a set of records and permissions grants into a 
single scoped namespace with a common owner.

The policy can have the standard attributes such as `account`, `owner`, and `id`.        
It's also required to have a `body` element, which contains:
        
* Records which are owned by the policy.
* `!permit` and `!grant` elements which apply to policy records.

Like a user or group, a policy is a role. All the records declared in the `body` of the policy are 
owned by the policy role. As a result, any role to whom the policy role is granted inherits
ownership of everything defined in the policy. Typically, this is the policy owner.

Policies should be self-contained; they should avoid making any reference to 
records from outside the policy. This way, the policy can be loaded with different
owner and namespace prefix options to serve different functions in the workflow.
For example, a can be loaded into the `dev` namespace with owner `!group developers`, 
then a "dev" version of the policy is created with full management assigned to the `developers` group.
It can also be loaded into the `prod` namespace with owner `!group operations`, creating
a production version of the same policy.
)

        self.example = %(
- !policy
  id: webserver
  body:
  - &secrets
    - !variable ssl/private-key
 
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
          @body ||= []
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
