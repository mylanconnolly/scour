module Scour
  module Searchable
    extend ActiveSupport::Concern

    included do
    end

    class_methods do
      def scour(criteria = nil)
        return self if criteria.nil?

        CriteriaParser.new(all, criteria).parse
      end
    end
  end
end
