module Conjur::PolicyParser::Types
  class Deny < Base
    attribute :role, kind: :role, dsl_accessor: true
    attribute :privilege, kind: :string, dsl_accessor: true
    attribute :resource, dsl_accessor: true
        
    include ResourceMemberDSL

    def delete_statement?; true; end

    def subject_id
      resource.id
    end

    def to_s
      "Deny #{role} to '#{privilege}' #{resource}"
    end
  end
end
