module Conjur
  module PolicyParser
    module Types
      class Delete < Base
        attribute :record, kind: :resource

        def delete_statement?; true; end

        def to_s
          "Delete #{record}"
        end
      end
    end
  end
end
