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
      @joins.reduce(query) { |rel, join| rel.left_joins(join) }
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
        criteria = column_name(klass, col)

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
        .map { |pred, arg| parse_column_expression(key, pred, arg, klass) }
        .compact
        .reduce(&:and)
    end

    def parse_column_expression(key, pred, arg, klass)
      column = column_name(klass, key)

      if arg.is_a?(Hash) && arg.key?(:column)
        column.send(pred, column_name(klass, arg[:column]))
      elsif AREL_PREDICATES.include?(pred.to_sym)
        column.send(pred, arg)
      end
    end

    def associations(klass)
      klass.reflect_on_all_associations.index_by(&:name)
    end

    def column_name(klass, column)
      if column.to_s.include?('.')
        parts = column.to_s.split('.')
        k = klass

        parts.each do |part|
          return k.arel_table[column] if k.column_names.include?(part)

          k = k.reflect_on_association(part).klass
          @joins |= [part.to_sym]
        end
      else
        klass.arel_table[column]
      end
    end
  end
end
