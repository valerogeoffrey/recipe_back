# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecipeIngredients::Units do
  describe 'UNITS' do
    it 'contains expected common units' do
      expect(described_class::UNITS).to include('cup', 'teaspoon', 'tablespoon')
    end

    it 'contains both singular and plural forms' do
      expect(described_class::UNITS).to include('cup', 'cups')
      expect(described_class::UNITS).to include('ounce', 'ounces')
    end

    it 'contains abbreviated units' do
      expect(described_class::UNITS).to include('tbsp', 'oz', 'g', 'kg', 'lb', 'ml', 'dl')
    end

    it 'is frozen' do
      expect(described_class::UNITS).to be_frozen
    end
  end

  describe 'FRACTIONS' do
    it 'contains common fraction characters' do
      expect(described_class::FRACTIONS).to eq('¼½¾⅓⅔⅕⅙⅛⅜⅝⅞')
    end

    it 'is a string' do
      expect(described_class::FRACTIONS).to be_a(String)
    end
  end

  describe '.units_regex' do
    let(:regex) { described_class.units_regex }

    it 'returns a Regexp object' do
      expect(regex).to be_a(Regexp)
    end

    it 'matches unit at the beginning of string' do
      expect('cup flour').to match(regex)
      expect('cups sugar').to match(regex)
    end

    it 'does not match when number precedes unit' do
      expect('2 cups sugar').not_to match(regex)
    end

    it 'is case insensitive' do
      expect('Cup flour').to match(regex)
      expect('CUPS sugar').to match(regex)
      expect('TbSp oil').to match(regex)
    end

    it 'matches units with optional plural "s"' do
      expect('cup flour').to match(regex)
      expect('cups flour').to match(regex)
    end

    it 'requires space after unit' do
      expect('cup flour').to match(regex)
      expect('cupflour').not_to match(regex)
    end

    it 'only matches at the start of string' do
      expect('add cup flour').not_to match(regex)
    end

    context 'with various units' do
      it 'matches volume units' do
        expect('teaspoon salt').to match(regex)
        expect('tablespoon butter').to match(regex)
        expect('ml water').to match(regex)
        expect('liter milk').to match(regex)
      end

      it 'matches weight units' do
        expect('gram sugar').to match(regex)
        expect('kg flour').to match(regex)
        expect('pound beef').to match(regex)
        expect('oz cheese').to match(regex)
      end

      it 'matches count units' do
        expect('can tomatoes').to match(regex)
        expect('package pasta').to match(regex)
        expect('slice bread').to match(regex)
        expect('clove garlic').to match(regex)
      end

      it 'matches abbreviated forms' do
        expect('tbsp oil').to match(regex)
        expect('oz flour').to match(regex)
        expect('lb meat').to match(regex)
      end
    end

    context 'edge cases' do
      it 'does not match non-unit words' do
        expect('hello world').not_to match(regex)
        expect('ingredient list').not_to match(regex)
      end

      it 'matches units with parentheses notation' do
        expect('tablespoon(s) sugar').to match(regex)
        expect('teaspoon(s) vanilla').to match(regex)
      end
    end

    context 'usage in string substitution' do
      it 'can remove unit from beginning of string' do
        result = 'cup flour'.gsub(regex, '')
        expect(result).to eq('flour')
      end

      it 'removes unit with plural s' do
        result = 'cups sugar'.gsub(regex, '')
        expect(result).to eq('sugar')
      end
    end
  end
end
