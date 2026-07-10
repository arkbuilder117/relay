module Catalog
  module Services
    class ISRCMatcher
      def self.valid?(isrc)
        isrc.present? && isrc.match?(Catalog::ValueObjects::ISRC::PATTERN)
      end
    end
  end
end
