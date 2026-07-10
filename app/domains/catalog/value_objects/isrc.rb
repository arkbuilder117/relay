module Catalog
  module ValueObjects
    class ISRC
      PATTERN = /\A[A-Z]{2}[A-Z0-9]{3}\d{7}\z/

      attr_reader :value

      def initialize(value)
        raise ArgumentError, "Invalid ISRC: #{value}" unless value.to_s.match?(PATTERN)
        @value = value.to_s.upcase
      end

      def to_s = @value
      def ==(other) = other.is_a?(ISRC) && value == other.value
    end
  end
end
