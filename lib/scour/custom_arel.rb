module Arel
  module Nodes
  end

  module Predications
    def eq_hour(other) = date_trunc_criteria('hour', other)

    def eq_day(other) = date_trunc_criteria('day', other)

    def eq_week(other) = date_trunc_criteria('week', other)

    def eq_month(other) = date_trunc_criteria('month', other)

    def eq_quarter(other) = date_trunc_criteria('quarter', other)

    def eq_year(other) = date_trunc_criteria('year', other)

    private

    def date_trunc_criteria(unit, other) = date_trunc(unit, self).eq(date_trunc(unit, other))

    def date_trunc(unit, value)
      Nodes::NamedFunction.new('DATE_TRUNC', [unit, value].map { |v| maybe_quote_value(v) })
    end

    def maybe_quote_value(value)
      case value
      when Arel::Attributes::Attribute, Arel::Nodes::Quoted then value
      else Arel::Nodes::Quoted.new(value)
      end
    end
  end
end
