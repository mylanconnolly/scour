module Scour
  class CriteriaParser
    # These are the predicates already available in Arel, which we can just use
    # as-is.
    AREL_PREDICATES = %i[
      eq
      eq_hour
      eq_day
      eq_week
      eq_month
      eq_quarter
      eq_year
      not_eq
      gt
      gteq
      lt
      lteq
      matches
      does_not_match
      matches_regexp
      does_not_match_regexp
    ].freeze

    def initialize(relation, criteria)
      @relation = relation
      @criteria = criteria
      @klass = relation.klass
      @columns = @klass.column_names
      @joins = []
    end

    def parse
      query = @relation.where(parse_criteria(@klass))
      @joins.reduce(query) { |rel, join| rel.joins(join) }
    end

    private

    def parse_criteria(klass)
      @criteria
        .map { |key, value| parse_criteria_group(key, value, klass) }
        .compact
        .reduce(&:and)
    end

    def parse_criteria_group(key, group, klass)
      case key.to_sym
      when :or then parse_or(group, klass)
      when :and then parse_and(group, klass)
      else parse_node(key, group, klass)
      end
    end

    def parse_or(group, klass)
      group
        .map { |key, value| parse_criteria_group(key, value, klass) }
        .compact
        .reduce(&:or)
    end

    def parse_and(group, klass)
      group
        .map { |key, value| parse_criteria_group(key, value, klass) }
        .compact
        .reduce(&:and)
    end

    def parse_node(key, group, klass)
      if klass.column_names.include?(key.to_s)
        klass.arel_table.grouping(parse_column_criteria(key, group, klass))
      elsif key.to_s.include?('.')
        col, *fields = key.to_s.split('.')
        criteria = klass.arel_table[col]

        fields.each_with_index do |field, index|
          criteria = if index == fields.length - 1
                       Arel::Nodes::InfixOperation.new(:'->>', criteria, Arel::Nodes::Quoted.new(field))
                     else
                       Arel::Nodes::InfixOperation.new(:'->', criteria, Arel::Nodes::Quoted.new(field))
                     end
        end

        criteria
      else
        assocs = associations(klass)

        if (assoc = assocs[key.to_sym])
          parse_association(assoc, key, group)
        end
      end
    end

    def parse_association(assoc, key, group)
      @joins |= [key.to_sym]

      assoc.klass.arel_table.grouping(
        group.map { |k, v| parse_criteria_group(k, v, assoc.klass) }.reduce(&:and)
      )
    end

    def parse_column_criteria(key, value, klass)
      value
        .map { |pred, arg| klass.arel_table[key].send(pred, arg) if AREL_PREDICATES.include?(pred.to_sym) }
        .compact
        .reduce(&:and)
    end

    def associations(klass)
      klass.reflect_on_all_associations.index_by(&:name)
    end
  end
end
