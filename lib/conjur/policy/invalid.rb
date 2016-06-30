module Conjur
  module Policy
    class Invalid < Exception
      attr_reader :mark
      
      def initialize message, filename, mark
        super [ "Error at line #{mark.line}, column #{mark.column} in #{filename}", message ].join(' : ')
        @mark = mark
      end
    end
  end
end
