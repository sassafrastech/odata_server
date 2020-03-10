require "rails_helper"

describe OData::Core::Options::FilterOption do

  context "tokenize_filter_query" do
    it "handles integer literals" do
      tokens = OData::Core::Options::FilterOption.tokenize_filter_query("Prop eq 55")
      expect(tokens.length).to eq(3)
      expect(tokens[2]).to eq("55")
      # handle negative number
      tokens = OData::Core::Options::FilterOption.tokenize_filter_query("Prop eq -55")
      expect(tokens.length).to eq(3)
      expect(tokens[2]).to eq("-55")
    end

    it "handles decimal literals" do
      tokens = OData::Core::Options::FilterOption.tokenize_filter_query("Prop eq 55.3")
      expect(tokens.length).to eq(3)
      expect(tokens[2]).to eq("55.3")
    end

    it "handles string literals" do
      tokens = OData::Core::Options::FilterOption.tokenize_filter_query("Prop eq 'string'")
      expect(tokens.length).to eq(3)
      expect(tokens[2]).to eq("'string'")
    end

    # it "groups tokens" do
    #   # tokens = OData::Core::Options::FilterOption.tokenize_filter_query("(Foo eq 1 and Bar eq 2) or (Baz eq 3 and Bar eq 4)")
    #   # filters = OData::Core::Options::FilterOption.group_tokens(tokens)
    #   # assert_equal(3, filters.size)
    # end
  end

  # we organize the tokens into a tree with the highest precendence operators at the bottom of the tree (so they will
  # be evaluated first)
  context "parse_filter_query" do
    it "produces the correct AST" do
      filters = OData::Core::Options::FilterOption.parse_filter_query("Prop eq 5")
      expect(filters.size).to eq(3)
      expect(filters.value).to eq (:eq)
      expect(filters.left.value).to eq("Prop")
      expect(filters.right.value).to eq("5")
    end
  end

  context "tree_tokens" do
    it "attaches highest precendence to 'eq', next is 'and', and last is 'or'" do
      tokens = OData::Core::Options::FilterOption.tokenize_filter_query("a or c eq d and e eq f")
      tree = OData::Core::Options::FilterOption.tree_tokens(tokens)
      expect(tree.size).to eq(9), "incorrect size for token tree"
      expect(tree.left.size).to eq(1), "left-hand side should have only one node"
      expect(tree.value).to eq(:or), "wrong value for root"
      expect(tree.right.value).to eq(:and), "wrong value for right"
    end

    it "attaches higher precendence to 'or' than to 'gt' and 'lt'" do
      tokens = OData::Core::Options::FilterOption.tokenize_filter_query("baz lt 3 or baz gt 4")
      tree = OData::Core::Options::FilterOption.tree_tokens(tokens)
      expect(tree.size).to eq(7), "incorrect size for token tree"
      expect(tree.left.size).to eq(3), "left-hand side should have three nodes"
      expect(tree.right.size).to eq(3), "right-hand side should have three nodes"
      expect(tree.value).to eq(:or), "wrong value for root"
      expect(tree.left.value).to eq(:lt), "wrong value for left"
      expect(tree.right.value).to eq(:gt), "wrong value for right"
    end
  end

  context "find and apply filters" do
    let(:schema) { OData::AbstractSchema::Base.new }
    let(:ds) { OData::Edm::DataServices.new([schema]) }
    let(:entity_type) do
      entity_type = schema.EntityType("Foo")
      bar = entity_type.Property("bar", 'Edm.Int32', false)
      entity_type.Property("baz", 'Edm.Int32', false)
      entity_type.key_property = bar
      entity_type
    end
    let(:query) { entity_type; OData::Core::Parser.new(ds).parse!({ path: "Foos" }) }

    context "find_filter" do
      it "correctly finds the filter for a property" do
        filter = "bar add 5 eq 8 or baz eq 3"
        filter_option = OData::Core::Options::FilterOption.new(query, filter)
        expr = filter_option.find_filter(:baz)
        expect(expr).to_not be_nil
        expect(expr[0].value).to eq(3)
        expect(expr[0].property).to eq(:baz)
        expect(expr[0].operator).to eq(:eq)
      end

      it "correctly finds all expressions for a given property" do
        filter = "baz lt 3 or baz gt 4"
        filter_option = OData::Core::Options::FilterOption.new(query, filter)
        expr = filter_option.find_filter(:baz)
        expect(expr).to_not be_nil
        expect(expr.size).to eq(2)
        expect(expr[0].value).to eq(3)
        expect(expr[0].property).to eq(:baz)
        expect(expr[0].operator).to eq(:lt)
        expect(expr[1].value).to eq(4)
        expect(expr[1].property).to eq(:baz)
        expect(expr[1].operator).to eq(:gt)
      end
    end

    context "apply_filter" do
      it "correctly filters out properties excluded by the filter" do
        filter = "Bar add 5 eq 8 or Baz eq 3"
        filter_option = OData::Core::Options::FilterOption.new(query, filter)
        expect(filter_option.filter.value).to eq(:or)
        expect(filter_option.filter.left.value).to eq(:eq)
        expect(filter_option.filter.left.left.value).to eq(:add)
        expect(filter_option.filter.left.right.value).to eq('8')
        expect(filter_option.filter.right.value).to eq(:eq)
        entity = Test::Foo.new(1, 2, 4)
        res = filter_option.apply(entity_type, entity)
        expect(res).to be_falsey
        entity = Test::Foo.new(1, 2, 3)
        res = filter_option.apply(entity_type, entity)
        expect(res).to be_truthy
        entity = Test::Foo.new(1, 3, 4)
        res = filter_option.apply(entity_type, entity)
        expect(res).to be_truthy
      end
    end

  end
end
