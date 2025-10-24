# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::FilterValidator do
  describe '#validate!' do
    context 'with valid params' do
      it 'return true with valid title' do
        validator = described_class.new(title: 'Tarte aux pommes')
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'returns true with valid ingredient_ids' do
        validator = described_class.new(ingredient_ids: [1, 2, 3])
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'return true with valid title & ingredient_ids' do
        validator = described_class.new(
          title: 'Salade César',
          ingredient_ids: [1, 2, 3, 4, 5]
        )
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'returns true with empty params' do
        validator = described_class.new({})
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'returns true with empty title' do
        validator = described_class.new(title: nil)
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'returns true with empty ingredient_ids' do
        validator = described_class.new(ingredient_ids: nil)
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'accepts ingredient_ids as array of string' do
        validator = described_class.new(ingredient_ids: %w[1 2 3])
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'accepts title when is length is equal to his limit' do
        max_length = described_class::CONF[:title_max_length]
        validator = described_class.new(title: 'a' * max_length)
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'accepts ingredient_ids, when there number are equal to the max size' do
        max_ids = described_class::CONF[:max_ingredient_ids]
        validator = described_class.new(ingredient_ids: (1..max_ids).to_a)
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end
    end

    context 'with invalid title' do
      it 'returns ERR_TITLE_TOO_LONG' do
        max_length = described_class::CONF[:title_max_length]
        long_title = 'a' * (max_length + 1)
        validator = described_class.new(title: long_title)
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_TITLE_TOO_LONG)
      end

      it 'returns invalid char error when contain <' do
        validator = described_class.new(title: 'Recette <test>')
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_TITLE_INVALID_CHARS)
      end

      it 'returns invalid char error when contain >' do
        validator = described_class.new(title: 'Recette >test')
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_TITLE_INVALID_CHARS)
      end

      it 'returns invalid char error when contain " ' do
        validator = described_class.new(title: 'Recette "test"')
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_TITLE_INVALID_CHARS)
      end

      it 'returns invalid char error when contain \'' do
        validator = described_class.new(title: "Recette 'test'")
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_TITLE_INVALID_CHARS)
      end

      it 'returns invalid char error when contain &' do
        validator = described_class.new(title: 'Recette & test')
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_TITLE_INVALID_CHARS)
      end

      it 'returns an array of errors' do
        max_length = described_class::CONF[:title_max_length]
        invalid_title = "#{'a' * (max_length + 1)}<>"
        validator = described_class.new(title: invalid_title)
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_TITLE_TOO_LONG)
        expect(errors).to include(described_class::ERR_TITLE_INVALID_CHARS)
      end
    end

    context 'with invalid ingredient_ids' do
      it 'return an ERR_TOO_MANY_INGREDIENTS' do
        max_ids = described_class::CONF[:max_ingredient_ids]
        too_many_ids = (1..(max_ids + 1)).to_a
        validator = described_class.new(ingredient_ids: too_many_ids)
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_TOO_MANY_INGREDIENTS)
      end

      it 'returns ERR_INVALID_INGREDIENTS if contains strings' do
        validator = described_class.new(ingredient_ids: [1, 'abc', 3])
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
      end

      it 'returns ERR_INVALID_INGREDIENTS if contains special chars' do
        validator = described_class.new(ingredient_ids: [1, '2@3', 3])
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
      end

      it 'returns ERR_INVALID_INGREDIENTS if contains negative number' do
        validator = described_class.new(ingredient_ids: [1, -2, 3])
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
      end

      it 'returns ERR_INVALID_INGREDIENTS if contains float' do
        validator = described_class.new(ingredient_ids: [1, '2.5', 3])
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
      end

      it 'can return multiple errors in array' do
        max_ids = described_class::CONF[:max_ingredient_ids]
        invalid_ids = (1..max_ids).to_a + %w[abc def]
        validator = described_class.new(ingredient_ids: invalid_ids)
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_TOO_MANY_INGREDIENTS)
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
      end
    end

    context 'with mixed errors' do
      it 'returns all errors related to title and ingredient_ids' do
        max_length = described_class::CONF[:title_max_length]
        validator = described_class.new(
          title: "#{'a' * (max_length + 1)}<",
          ingredient_ids: [1, 'invalid', 3]
        )
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_TITLE_TOO_LONG)
        expect(errors).to include(described_class::ERR_TITLE_INVALID_CHARS)
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
        expect(errors.length).to eq(3)
      end
    end
  end

  describe '#errors' do
    it 'expose attr errors only for read' do
      validator = described_class.new(title: 'Test')
      expect(validator.errors).to eq([])
    end

    it 'contains error after validate!' do
      validator = described_class.new(title: 'Test <>')
      validator.validate!
      expect(validator.errors).to include(described_class::ERR_TITLE_INVALID_CHARS)
    end
  end

  describe '#filter_params' do
    it 'expose attr on read only' do
      params = { title: 'Test', ingredient_ids: [1, 2] }
      validator = described_class.new(params)
      expect(validator.filter_params).to eq(params)
    end
  end
end
