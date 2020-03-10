module OData::ActiveRecordSchema::Mixins
  module OptionTranslator

    def translate_filter(scope, predicate, left, right)
      if left.try(:left).present?
        pre_scope = translate_filter(scope, left.value, left.left, left.right)
        left = OpenStruct.new(value: pre_scope.constraints.first.to_sql)
      end

      left = left.value
      right = right.value

      case predicate.to_sym
      when :eq then scope.where("#{left} = #{right}")
      when :ne then scope.where("#{left} != #{right}")
      when :gt then scope.where("#{left} > #{right}")
      when :lt then scope.where("#{left} < #{right}")
      when :ge then scope.where("#{left} >= #{right}")
      when :le then scope.where("#{left} <= #{right}")
      when :and then scope.where(left).where(right)
      when :or then scope.where(left).or(right)
      when :add then scope.where("#{left} + #{right}")
      when :sub then scope.where("#{left} - #{right}")
      when :mul then scope.where("#{left} * #{right}")
      when :div then scope.where("#{left} / #{right}")
      when :mod then scope.where("#{left} % #{right}")
      else
        scope
      end
    end

    def translate_limitator(scope, predicate, value)
      case predicate.to_sym
      when :$skip then scope.offset(value)
      when :$top then scope.limit(value)
      else
        scope
      end
    end

  end
end
