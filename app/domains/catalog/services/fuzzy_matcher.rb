module Catalog
  module Services
    class FuzzyMatcher
      def self.searchable_title(title)
        title
          .gsub(/\(feat\..*?\)/i, "")
          .gsub(/- Remaster.*/i, "")
          .strip
      end
    end
  end
end
