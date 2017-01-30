module OData::ActiveRecordSchema::Mixins
  module OptionTranslator

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