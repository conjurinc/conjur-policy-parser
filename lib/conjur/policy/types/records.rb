# coding: utf-8
module Conjur
  module Policy
    module Types
      # A createable record type.
      class Record < Base
        def role?
          false
        end
        def resource?
          false
        end
      end
      
      module ActsAsResource
        def self.included(base)
          base.module_eval do
            attribute :id,   kind: :string, singular: true, dsl_accessor: true
            attribute :account, kind: :string, singular: true
            attribute :owner, kind: :role, singular: true, dsl_accessor: true
            
            attribute :annotations, kind: :hash, type: Hash, singular: true
            
            def description value
              annotation 'description', value
            end
            
            def annotation name, value
              self.annotations ||= {}
              self.annotations[name] = value
            end
          end
        end
        
        def initialize id = nil
          self.id = id if id
        end
        
        def to_s
          "#{resource_kind.gsub('_', ' ')} '#{id}'#{account && account != Conjur.configuration.account ? ' in account \'' + account + '\'': ''}"
        end
        
        def resourceid default_account = nil
          [ account || default_account, resource_kind, id ].join(":")
        end
        
        def resource_kind
          self.class.name.split("::")[-1].underscore
        end

        def resource_id
          id
        end
        
        def action
          :create
        end
        
        def resource?
          true
        end
        
        def immutable_attribute_names
          []
        end

      end
      
      module ActsAsRole
        def roleid default_account = nil
          [ account || default_account, role_kind, id ].join(":")
        end
        
        def role?
          true
        end
        
        def role_kind
          self.class.name.split("::")[-1].underscore
        end
        
        def role_id
          id
        end
      end
      
      module ActsAsCompoundId
        def initialize kind_or_id = nil, id_or_options = nil
          if kind_or_id && id_or_options && id_or_options.is_a?(String)
            self.kind = kind_or_id
            self.id = id_or_options
          elsif kind_or_id && kind_or_id.index(":")
            id_or_options ||= {}
            account, self.kind, self.id = kind_or_id.split(':', 3)
            self.account = account if account != id_or_options[:default_account]
          end
        end

        def == other
          other.kind_of?(ActsAsCompoundId) && kind == other.kind && id == other.id && account == other.account
        end

        def to_s
          "#{kind} #{self.class.short_name.underscore} '#{id}'#{account && account != Conjur.configuration.account ? ' in account \'' + account + '\'': ''}"
        end
      end
      
      class Role < Record
        include ActsAsRole
        include ActsAsCompoundId
        
        attribute :id,   kind: :string, singular: true, dsl_accessor: true
        attribute :kind, kind: :string, singular: true, dsl_accessor: true
        attribute :account, kind: :string, singular: true
        attribute :owner, kind: :role, singular: true, dsl_accessor: true

        self.description = %(
Create a custom role. 

The purpose of a role is to have privileges and to initiate
transactions.

A role may represent a person, a group, a non-human user (“robot”)
such as a virtual machine or process, or a group of other roles.

In addition to having privileges, a role can be granted to another
role.

When a role is granted, the receiving role gains all the privileges
of the granted role. In addition, it gains all the roles which are
held by the granted role; role grants are fully inherited.
        
Typically, roles are not defined directly.
Rather, records that behave as roles, such as Users, Groups,
Hosts and Layers are used instead.

See also: [role-based access control guide](/key_concepts/rbac.html)
)

        self.example = %(
- !user Beowulf

- !role tragic_end
    kind: destiny
    owner: !user Beowulf
)

        def roleid default_account = nil
          raise "account is required" unless account || default_account
          [ account || default_account, kind, id ].join(":")
        end
        
        def role_id; id; end
        def role_kind; kind; end
                  
        def immutable_attribute_names
          []
        end
      end
      
      class Resource < Record
        include ActsAsResource
        include ActsAsCompoundId

        attribute :kind, kind: :string, singular: true, dsl_accessor: true

        self.description = %(
Create a custom Resource.

Resources are the entities on which permissions are defined. A
resource id is an arbitrary, unique string which identifies the
protected asset.

Examples: database password, virtual machine or
server (for SSH access management), web service endpoint

Any Conjur resource can be annotated with a key-value pair. This
makes organization and discovery easier since annotations can be
searched on and are shown in the Conjur UI. Automation workflows
like rotation and expiration are based on annotations.

Typically, resources are not defined directly.
Rather, records that behave as resources, such as Users, Groups,
Hosts, Layers, Variables and Webservices are used instead.

See also: [role-based access control guide](/key_concepts/rbac.html)
)

        self.example = %(
- !user nobody

- !resource unicorn
    kind: magical_beast
    annotations:
      has_deadly_horn: true
      has_mercy: false
    owner: !user nobody
)

        def resource_kind
          kind
        end
      end
      
      class User < Record
        include ActsAsResource
        include ActsAsRole
        
        self.description = %(
A human user. 

**Note** For servers, VMs, scripts, PaaS applications, and other code actors, create Hosts instead of Users.
)

        self.attributes_description = {
          "uidnumber" => "An integer which is the user's uid number for Unix/Linux systems.",
          "public_keys" => "Stores public keys for the user, which can be retrieved through the public keys API. "
        }

        self.example = %(
- !user
  id: kevin
  uidnumber: 1208
  public_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAAD...+10trhK5Pt kgilpin@laptop

- !user
  id: bob
  uidnumber: 1209
  public_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAAD...DP2Kr5QzRl bob@laptop

- !grant
  role: !group security_admin
  member: !member
    role: !user kevin
    admin: true

- !grant
  role: !group operations
  member: !user bob
)

        attribute :uidnumber, kind: :integer, singular: true, dsl_accessor: true
        attribute :public_key, kind: :string, dsl_accessor: true

        def id_attribute; 'login'; end
        
        def custom_attribute_names
          [ :uidnumber, :public_key ]
        end
      end
      
      class Group < Record
        include ActsAsResource
        include ActsAsRole
        
        attribute :gidnumber, kind: :integer, singular: true, dsl_accessor: true

        self.description = %(
A group of users and other groups.

When a user becomes a member of a
group they are granted the group role, and inherit the group's privileges. 
Group members can be added with or without "admin option". With admin option,
the member can add and remove members to/from the group.
        
Groups can also be members of groups; in this way, groups can be organized and
nested in a hierarchy.
        
`security_admin` is the customary top-level group.
)

        self.attributes_description = {
          "gidnumber" => "An integer which is the group's gid number for Unix/Linux systems."
        }
               
        self.example = %(
- !user alice
- !user bob

- !group
  id: ops
  gidnumber: 110

- !grant
    role: !group ops
    members:
    - !user alice
    - !member
        role: !user bob
        admin: true
)
        def custom_attribute_names
          [ :gidnumber ]
        end
      end
      
      class Host < Record
        include ActsAsResource
        include ActsAsRole

        self.description = %(
A machine or code; for example, a server, VM, job or container.
        
Hosts defined in a policy are generally long-lasting hosts, and assigned to a
layer through a `!grant` entitlement. Assignment to layers is the primary way
for hosts to get privileges, and also the primary way that users obtain access to hosts.
)
        
        self.privileges_description = {
          "execute" => "SSH users should have login privileges to the host **without admin** privileges.",
          "update" => "SSH users should have login privileges to the host **with admin** privileges.",
        }

        self.example = %(
- !host
  id: www-01.home.cern
  annotations:
    description: Hypertext web server
        
- !grant
  role: !layer webservers
  member: !host www-01.cern.org
)
      end
      
      class Layer < Record
        include ActsAsResource
        include ActsAsRole

        self.description = %(
Host are organized into sets called "layers" (sometimes known in some other 
systems as "host groups"). Layers map logically to the groups of machines and
code in your infrastructure. For example, a group of servers or VMs can be a layer;
a cluster of containers which are performing the same function (e.g. running the same image)
can also be modeled as a layer. A script which is deployed to a server can be a layer.
And an application which is deployed to a PaaS can also be a layer.

Using layers to model the privileges of code helps to separate the permissions from the
physical implementation of the application. For example, if an application is migrated from a PaaS to a 
container cluster, the logical layers that compose the application (web servers, app servers, database tier,
cache, message queue) can remain the same.
        
**Automatic roles**
        
When a layer is created, it automatically creates three additional roles. The name of these
automatic roles are `use_host`, and `admin_host`. When a host is added to the layer
(by granting the layer to the host), the layer automatically gives privileges on the host to the
automatic roles:

* **use_host** gets `execute` privilege on the host
* **admin_host** gets `update` privilege on the host
        
If the host is removed from the layer, then these privileges are revoked.
        
Automatic roles are granted using the `!automatic-role` tag, described below.
)

        self.example = %(
        
- !layer prod/database
        
- !layer prod/app

- !group operations
        
- !host db-01
- !host app-01
- !host app-02

- !grant
  role: !layer prod/database
  member: !host db-01

- !grant
  role: !layer prod/app
  members:
  - !host app-01
  - !host app-02
        
- !grant
  role: !automatic-role
    record: !layer prod/app
    role_name: admin_host
  member: !group operations
)
      end
      
      class Variable < Record
        include ActsAsResource
        
        attribute :kind,      kind: :string, singular: true, dsl_accessor: true
        attribute :mime_type, kind: :string, singular: true, dsl_accessor: true

        self.description = %(
Create a container which holds a sequence of encrypted data values.

Variables can hold any ASCII-armored value. Variable values are
versioned. Any version of the variable is available through the API, 
however the latest version is returned by
default.
)

        self.privileges_description = {
          "execute" => "Fetch the default value or any historical value",
          "update" => "Add a new value"
        }
        
        self.attributes_description = {
          "kind" => "Assigns a descriptive kind to the variable, such as 'password' or 'SSL private key'.",
          "mime_type" => "the expected MIME type of the values. This attribute is used to set the Content-Type header on HTTP responses."
        }

        self.example = %(
- !variable
  id: prod/db/password
  kind: password

- !variable
  id: prod/app/ssl/private_key
  kind: SSL private key
  mime_type: application/x-pem-file

- !layer prod/db
        
- !layer prod/app

- !permit
  role: !layer prod/app
  privileges: [ read, execute ]
  resources:
  - !variable prod/db/password
  - !variable prod/app/ssl/private-key
)

        def custom_attribute_names
          [ :kind, :mime_type ]
        end
        
        def immutable_attribute_names
          [ :kind, :mime_type ]
        end
      end
      
      class Webservice < Record
        include ActsAsResource

        self.description = %(
Represents a web service endpoint, typically an HTTP(S) service.

Permission grants are straightforward: an input
HTTP request path is mapped to a webservice resource id. The HTTP
method is mapped to an RBAC privilege. A permission check is
performed, according to the following transaction:

* **role** client incoming role on the HTTP request. The client can be obtained from an Authorization header (e.g. signed
  access token), or from the subject name of an SSL client certificate.
* **privilege** `read`, `update`, or `delete` according to HTTP verb
* **resource** web service resource id
)

        self.example = %(
- !group analysts

- !webservice
  id: xkeyscore
  annotations:
    description: API endpoint for surveillance apparatus

- !permit
  role: !group analysts
  privilege: read
  resource: !webservice xkeyscore
)
      end
      
      class HostFactory < Record
        include ActsAsResource

        self.description = %(
Create a host-factory service for automatically creating [Hosts](#reference/host) 
and enrolling them into one or more [Layer](#reference/layer)s.
)

        self.example = %(
- !layer nest

- !host-factory
    annotations:
      description: Factory to create new bird hosts
    layers: [ !layer nest ]
)
        
        attribute :role, kind: :role, dsl_accessor: true, singular: true
        attribute :layer, kind: :layer, dsl_accessor: true
        
        alias role_accessor role
        
        def role *args
          if args.empty?
            role_accessor || self.owner
          else
            role_accessor(*args)
          end
        end
      end
      
      class AutomaticRole < Base
        include ActsAsRole
        
        def initialize record = nil, role_name = nil
          self.record = record if record
          self.role_name = role_name if role_name
        end
        
        attribute :record,    kind: :role,   singular: true
        attribute :role_name, kind: :string, singular: true

        self.description = %(
Some [Roles](#reference/role) are created automatically by a containing record. 
        
These roles are accessed by using the `automatic-role`
type, which identifies the containing record (e.g. a Layer), and the name of the automatic role (e.g. `use_host`).

The automatic roles of a Layer are:

* **use_host**, for allowing SSH access to each host as the `users` primary group.
* **admin_host**, for allowing SSH access to each host as the `conjurers` primary group.
* **observe**, for `read` privileges on the hosts.
)

        self.example = %(
- !user chef
- !user owner
- !group line-cooks
- !layer kitchen

# There's no need to create automatic roles explicitly

- !grant
    role: !automatic-role
      record: !layer kitchen
      role_name: use_host
    member: !group line-cooks

- !grant
    role: !automatic-role
      record: !layer kitchen
      role_name: admin_host
    member: !user chef

- !grant
    role: !automatic-role
      record: !layer kitchen
      role_name: observe
    member: !user owner
)
        
        class << self
          def build fullid
            account, kind, id = fullid.split(':', 3)
            raise "Expecting @ for kind, got #{kind}" unless kind == "@"
            id_tokens = id.split('/')
            record_kind = id_tokens.shift
            role_name = id_tokens.pop
            record = Conjur::Policy::Types.const_get(record_kind.classify).new.tap do |record|
              record.id = id_tokens.join('/')
              record.account = account
            end
            self.new record, role_name
          end
        end
        
        def to_s
          role_name = self.id.split('/')[-1]
          "'#{role_name}' on #{record}"
        end
        
        def account
          record.account
        end
        
        def role_kind
          "@"
        end
        
        def id
          [ record.role_kind, record.id, role_name ].join('/')
        end
      end
    end
  end
end
