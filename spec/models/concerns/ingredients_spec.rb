# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ingredients::Parsable do
  # Crée une classe de test pour tester le concern
  let(:test_class) do
    Class.new do
      include Ingredients::Parsable
    end
  end

  before do
    # Stub FoodIngredientParser pour permettre le mocking
    food_parser_class = Class.new do
      def self.parse(_ingredient_string)
        nil
      end
    end
    stub_const('FoodIngredientParser', food_parser_class)
  end

  describe '.parse' do
    context 'when parsing succeeds with ingreedy' do
      let(:parsed_result) { double('Ingreedy', ingredient: 'flour', amount: 2, unit: 'cups') }

      before do
        allow(Ingreedy).to receive(:parse).with('2 cups flour').and_return(parsed_result)
      end

      it 'returns a success result' do
        result = test_class.parse('2 cups flour')
        expect(result).to be_a(Result)
        expect(result.success?).to be true
      end

      it 'contains the parsed data' do
        result = test_class.parse('2 cups flour')
        expect(result.data).to eq(parsed_result)
      end
    end

    context 'when ingreedy fails but food_parser succeeds' do
      let(:parsed_result) { double('FoodParser', ingredient: 'sugar', amount: 1, unit: 'cup') }

      before do
        allow(Ingreedy).to receive(:parse).and_raise(Ingreedy::ParseFailed)
        allow(FoodIngredientParser).to receive(:parse).with('1 cup sugar').and_return(parsed_result)
      end

      it 'returns a success result from food_parser' do
        result = test_class.parse('1 cup sugar')
        expect(result.success?).to be true
        expect(result.data).to eq(parsed_result)
      end
    end

    context 'when both parsers fail but fallback is enabled' do
      before do
        allow(Ingreedy).to receive(:parse).and_raise(Ingreedy::ParseFailed)
        allow(FoodIngredientParser).to receive(:parse).and_return(nil)
      end

      it 'uses fallback parser' do
        result = test_class.parse('some ingredient')
        expect(result.success?).to be true
        expect(result.data.ingredient).to eq('some ingredient')
      end

      it 'fallback result has nil amount and unit' do
        result = test_class.parse('some ingredient')
        expect(result.data.amount).to be_nil
        expect(result.data.unit).to be_nil
      end
    end

    context 'when fallback is disabled' do
      before do
        allow(Ingreedy).to receive(:parse).and_raise(Ingreedy::ParseFailed)
        allow(FoodIngredientParser).to receive(:parse).and_return(nil)
      end

      it 'returns a failed result' do
        result = test_class.parse('some ingredient', config: { enable_fallback: false })
        expect(result.success?).to be false
        expect(result.message).to include('Unable to parse ingredient')
      end
    end

    context 'when all parsing methods fail with fallback enabled' do
      before do
        allow(Ingreedy).to receive(:parse).and_raise(Ingreedy::ParseFailed)
        allow(FoodIngredientParser).to receive(:parse).and_return(nil)
        allow(RecipeIngredients::Units).to receive(:units_regex).and_return(/^never_matches/)
      end

      it 'returns failed result for blank string after fallback cleaning' do
        result = test_class.parse('123')
        expect(result.success?).to be false
      end
    end

    context 'when an exception occurs during ingreedy parsing' do
      before do
        allow(Ingreedy).to receive(:parse).and_raise(StandardError.new('Unexpected error'))
        allow(FoodIngredientParser).to receive(:parse).and_return(nil)
      end

      it 'catches the error and tries next parser' do
        result = test_class.parse('bad input')
        # Le fallback devrait être utilisé
        expect(result.success?).to be true
      end
    end
  end

  describe '.extract_ingredient_name' do
    context 'with object responding to ingredient' do
      let(:parsed) { double('Parsed', ingredient: 'flour') }

      it 'returns the ingredient name' do
        expect(test_class.extract_ingredient_name(parsed)).to eq('flour')
      end

      it 'strips whitespace' do
        allow(parsed).to receive(:ingredient).and_return('  flour  ')
        expect(test_class.extract_ingredient_name(parsed)).to eq('flour')
      end
    end

    context 'with hash' do
      it 'returns ingredient from hash key' do
        parsed = { ingredient: 'sugar' }
        expect(test_class.extract_ingredient_name(parsed)).to eq('sugar')
      end

      it 'strips whitespace from hash value' do
        parsed = { ingredient: '  sugar  ' }
        expect(test_class.extract_ingredient_name(parsed)).to eq('sugar')
      end
    end

    context 'with nil' do
      it 'returns nil' do
        expect(test_class.extract_ingredient_name(nil)).to be_nil
      end
    end

    context 'with object not responding to ingredient' do
      it 'returns nil' do
        expect(test_class.extract_ingredient_name(Object.new)).to be_nil
      end
    end
  end

  describe '.extract_quantity' do
    context 'with amount and unit' do
      let(:parsed) { double('Parsed', amount: 2, unit: 'cups') }

      it 'returns formatted quantity' do
        expect(test_class.extract_quantity(parsed)).to eq('2 cups')
      end
    end

    context 'with only amount' do
      let(:parsed) { double('Parsed', amount: 3, unit: nil) }

      it 'returns only amount' do
        expect(test_class.extract_quantity(parsed)).to eq('3')
      end
    end

    context 'with only unit' do
      let(:parsed) { double('Parsed', amount: nil, unit: 'pinch') }

      it 'returns only unit' do
        expect(test_class.extract_quantity(parsed)).to eq('pinch')
      end
    end

    context 'with neither amount nor unit' do
      let(:parsed) { double('Parsed', amount: nil, unit: nil) }

      it 'returns nil' do
        expect(test_class.extract_quantity(parsed)).to be_nil
      end
    end

    context 'with object not responding to amount or unit' do
      it 'returns nil' do
        expect(test_class.extract_quantity(Object.new)).to be_nil
      end
    end
  end

  describe '.extract_unit' do
    context 'with object responding to both unit and container_unit' do
      let(:parsed) { double('Parsed', unit: 'cups', container_unit: 'box') }

      before do
        allow(parsed).to receive(:respond_to?).with(:unit).and_return(true)
        allow(parsed).to receive(:respond_to?).with(:container_unit).and_return(true)
      end

      it 'returns the unit' do
        expect(test_class.extract_unit(parsed)).to eq('cups')
      end
    end

    context 'with object only responding to container_unit' do
      let(:parsed) { double('Parsed') }

      before do
        allow(parsed).to receive(:respond_to?).with(:unit).and_return(false)
        allow(parsed).to receive(:respond_to?).with(:container_unit).and_return(true)
        allow(parsed).to receive(:container_unit).and_return('can')
      end

      it 'returns the container_unit' do
        expect(test_class.extract_unit(parsed)).to eq('can')
      end
    end

    context 'with object not responding to unit or container_unit' do
      it 'returns :unit symbol' do
        expect(test_class.extract_unit(Object.new)).to eq(:unit)
      end
    end
  end

  describe '.extract_amount' do
    context 'with object responding to amount' do
      let(:parsed) { double('Parsed', amount: 2.5) }

      it 'returns the amount' do
        expect(test_class.extract_amount(parsed)).to eq(2.5)
      end
    end

    context 'with object not responding to amount' do
      it 'returns nil' do
        expect(test_class.extract_amount(Object.new)).to be_nil
      end
    end

    context 'with nil amount' do
      let(:parsed) { double('Parsed', amount: nil) }

      it 'returns nil' do
        expect(test_class.extract_amount(parsed)).to be_nil
      end
    end
  end

  describe '.parse_with_ingreedy' do
    it 'calls Ingreedy.parse' do
      expect(Ingreedy).to receive(:parse).with('2 cups flour')
      test_class.send(:parse_with_ingreedy, '2 cups flour')
    end

    context 'when parsing succeeds' do
      let(:parsed_result) { double('Ingreedy', ingredient: 'flour') }

      before do
        allow(Ingreedy).to receive(:parse).and_return(parsed_result)
      end

      it 'returns the parsed result' do
        result = test_class.send(:parse_with_ingreedy, '2 cups flour')
        expect(result).to eq(parsed_result)
      end
    end

    context 'when parsing fails' do
      before do
        allow(Ingreedy).to receive(:parse).and_raise(Ingreedy::ParseFailed)
      end

      it 'returns nil' do
        result = test_class.send(:parse_with_ingreedy, 'invalid')
        expect(result).to be_nil
      end
    end

    context 'when result has no ingredient' do
      before do
        allow(Ingreedy).to receive(:parse).and_return(double('Ingreedy', ingredient: nil))
      end

      it 'returns nil' do
        result = test_class.send(:parse_with_ingreedy, 'test')
        expect(result).to be_nil
      end
    end
  end

  describe '.parse_with_food_parser' do
    it 'calls FoodIngredientParser.parse' do
      expect(FoodIngredientParser).to receive(:parse).with('1 cup sugar')
      test_class.send(:parse_with_food_parser, '1 cup sugar')
    end

    context 'when parsing succeeds' do
      let(:parsed_result) { double('FoodParser', ingredient: 'sugar') }

      before do
        allow(FoodIngredientParser).to receive(:parse).and_return(parsed_result)
      end

      it 'returns the parsed result' do
        result = test_class.send(:parse_with_food_parser, '1 cup sugar')
        expect(result).to eq(parsed_result)
      end
    end

    context 'when parsing fails' do
      before do
        allow(FoodIngredientParser).to receive(:parse).and_raise(StandardError)
      end

      it 'returns nil' do
        result = test_class.send(:parse_with_food_parser, 'invalid')
        expect(result).to be_nil
      end
    end

    context 'when result has no ingredient' do
      before do
        allow(FoodIngredientParser).to receive(:parse).and_return(double('FoodParser', ingredient: nil))
      end

      it 'returns nil' do
        result = test_class.send(:parse_with_food_parser, 'test')
        expect(result).to be_nil
      end
    end
  end

  describe '.parse_with_fallback' do
    before do
      allow(RecipeIngredients::Units).to receive(:units_regex).and_return(/^(cup|cups|teaspoon)\s+/i)
    end

    it 'removes leading numbers' do
      result = test_class.send(:parse_with_fallback, '2 flour')
      expect(result.ingredient).to eq('flour')
    end

    it 'removes unit patterns' do
      result = test_class.send(:parse_with_fallback, 'cup flour')
      expect(result.ingredient).to eq('flour')
    end

    it 'removes both numbers and units' do
      result = test_class.send(:parse_with_fallback, '2 cups flour')
      expect(result.ingredient).to eq('flour')
    end

    it 'strips whitespace' do
      result = test_class.send(:parse_with_fallback, '  flour  ')
      expect(result.ingredient).to eq('flour')
    end

    it 'returns nil for blank result' do
      result = test_class.send(:parse_with_fallback, '123')
      expect(result).to be_nil
    end

    it 'returns OpenStruct with nil amount and unit' do
      result = test_class.send(:parse_with_fallback, 'ingredient name')
      expect(result).to be_a(OpenStruct)
      expect(result.amount).to be_nil
      expect(result.unit).to be_nil
    end

    context 'with complex number patterns' do
      it 'removes fractions' do
        result = test_class.send(:parse_with_fallback, '1/2 teaspoon salt')
        expect(result.ingredient).to eq('salt')
      end

      it 'removes decimals' do
        result = test_class.send(:parse_with_fallback, '2.5 sugar')
        expect(result.ingredient).to eq('sugar')
      end
    end
  end
end
