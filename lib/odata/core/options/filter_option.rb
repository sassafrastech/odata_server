module Odata
  module Core
    module Options
      def self.filters(options)
        options.find { |o| o.option_name == Odata::Core::Options::FilterOption.option_name } unless options.nil?
      end
      
      class BinaryTree
        attr_reader :left, :value, :right
        
        def initialize(value, left, right)
          @left = left
          @value = value
          @right = right
        end
        
        def size
          size = 1
          size += @left.size  unless left.nil?
          size += @right.size unless right.nil?
          size
        end
            
        def each
          @left.each { |node| yield node } unless @left.nil?
          yield self
          @right.each { |node| yield node } unless @right.nil?
        end
      end
      
      class GroupExpression
        attr_reader :filters

        def initialize(filters)
          @filters = filters
        end
      end

      class CompoundExpression
        attr_reader :conjunction, :left, :right

        def initialize(conjunction, left, right)
          @conjunction = conjunction
          @left = left
          @right = right
        end
      end
      
      class FilterExpression
        attr_reader :property, :operator, :value
        
        def initialize(prop, op, value)
          @property = prop
          @operator = op
          @value = value
        end
      end
      
      class FilterOption < Odata::Core::Option
        LOGICAL_OPERATORS = %w(eq ne gt ge lt le)
        CONJUNCTIONS = %w(and or)
        NEGATION = %w(not)
        ARITHMETIC_OPERATORS = %w(add sub mul div mod)
        PRECEDENCE = (LOGICAL_OPERATORS | CONJUNCTIONS | NEGATION | ARITHMETIC_OPERATORS)

        attr_reader :filter
        
        def self.option_name
          '$filter'
        end

        def initialize(query, value)
          super(query, self.class.option_name)
          @value = value
          @filter = FilterOption.parse_filter_query(value) unless value.nil?
        end
        
        def self.parse!(query, key, value = nil)
          return nil unless key == self.option_name
          
          query.Option(self, value)
        end
        
        def self.applies_to?(query)
          true
        end
        
        def entity_type
          return nil if self.query.segments.empty?
          return nil unless self.query.segments.last.respond_to?(:entity_type)
          @entity_type ||= self.query.segments.last.entity_type
        end
        
        def valid?
          entity_type = self.entity_type
          return false if entity_type.blank?
          true
        end
        
        def apply(entity_type, entity)
          ret = eval_token(entity_type, entity, @filter)
          return nil unless ret
          entity
        end
        
        def find_filter(prop)
          token = @filter
          found_filters = []
          find_filter_from_token(prop, token, found_filters)
          found_filters
        end
        
private
        def find_filter_from_token(prop, token, found_filters)
          return if token.nil?
          if token.left != nil && token.left.value.to_sym == prop
            found_filters << FilterExpression.new(prop, token.value, eval_literal(token.right.value))
          end
          find_filter_from_token(prop, token.left, found_filters)
          find_filter_from_token(prop, token.right, found_filters)
        end
        
        def eval_token(entity_type, entity, token)
          return nil if token.nil? 
          val = token.value
          left_val = eval_token(entity_type, entity, token.left)
          right_val = eval_token(entity_type, entity, token.right)
          ret = case val
          when :eq
            left_val.to_s == right_val.to_s
          when :ne
            left_val.to_s != right_val.to_s
          when :gt
            left_val > right_val
          when :lt
            left_val < right_val
          when :ge
            left_val >= right_val
          when :le
            left_val <= right_val
          when :and
            left_val && right_val
          when :or
            left_val || right_val
          when :add
            left_val + right_val
          else
            eval_property_or_literal(entity_type, entity, val)
          end
          ret
        end
        
        def eval_property_or_literal(entity_type, entity, val)
          if prop = entity_type.find_property(val) then
            return prop.value_for(entity)
          end
          eval_literal(val)
        end
        
        def eval_literal(val)
          if val.start_with?("'") and val.end_with?("'") then
            # strip quotes off of the string literal
            return val[1, val.size - 2]
          end
          val.to_i
        end

        def self.parse_filter_query(filter_query)
          state = :property
          tokens = tokenize_filter_query(filter_query)
          tree_tokens(tokens)
        end
        
        def self.tokenize_filter_query(filter_query)
          tokens = filter_query.split(/(\S*)/).compact.keep_if { |x| x.strip.length > 0 }
          tokens
        end
        
        def self.tree_tokens(tokens)
          highest_precedence = -1
          operator, left, right = nil
          if tokens.nil? then return nil end
          if tokens.size == 1 then
            return BinaryTree.new(tokens[0], nil, nil) 
          end
          tokens.each_with_index do |token, idx|
            if PRECEDENCE.include?(token) then
              token_precedence = PRECEDENCE.index(token)
              if token_precedence > highest_precedence then
                operator = token
                left = tokens[0, idx]
                right = tokens[idx + 1, tokens.length]
                highest_precedence = token_precedence
              end
            end
          end
          if LOGICAL_OPERATORS.include?(operator) or ARITHMETIC_OPERATORS.include?(operator) then
            this_expr = BinaryTree.new(operator.to_sym, tree_tokens(left), BinaryTree.new(right[0], nil, nil))
            if (right.size >= 2)
              BinaryTree.new(right[1].to_sym, this_expr, tree_tokens(right[2, right.size]))
            else
              this_expr
            end
          else
            BinaryTree.new(operator.to_sym, tree_tokens(left), tree_tokens(right))
          end
        end
 
      end
    end
  end
end
