module Conjur
  module PolicyParser
    module Types
      class Revoke < Base
        attribute :role, dsl_accessor: true
        attribute :member, kind: :role, dsl_accessor: true

        def delete_statement?; true; end

        def to_s
          "Revoke #{role} from #{member}"
        end
      end
    end
  end
end