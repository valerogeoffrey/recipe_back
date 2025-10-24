# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ingredients::FilterValidator do
  describe '#validate!' do
    context 'with valid parameters' do
      it 'returns true with a valid name' do
        validator = described_class.new(name: 'Tomato')
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'returns true with valid ids' do
        validator = described_class.new(ids: [1, 2, 3])
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'returns true with both valid name and ids' do
        validator = described_class.new(
          name: 'Carrot',
          ids: [1, 2, 3, 4, 5]
        )
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'returns true with empty parameters' do
        validator = described_class.new({})
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'returns true with nil name' do
        validator = described_class.new(name: nil)
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'returns true with nil ids' do
        validator = described_class.new(ids: nil)
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'returns true with empty string name' do
        validator = described_class.new(name: '')
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'returns true with empty array ids' do
        validator = described_class.new(ids: [])
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'accepts ids as string numbers' do
        validator = described_class.new(ids: %w[1 2 3])
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'accepts a name at maximum character limit' do
        max_length = described_class::CONF[:title_max_length]
        validator = described_class.new(name: 'a' * max_length)
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'accepts maximum number of ids' do
        max_ids = described_class::CONF[:max_ingredient_ids]
        validator = described_class.new(ids: (1..max_ids).to_a)
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'accepts names with spaces and special characters' do
        validator = described_class.new(name: 'Crème fraîche épaisse')
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end

      it 'accepts names with numbers' do
        validator = described_class.new(name: 'Ingredient123')
        success, errors = validator.validate!

        expect(success).to be true
        expect(errors).to be_empty
      end
    end

    context 'with invalid name' do
      it 'returns an error if name is too long' do
        max_length = described_class::CONF[:title_max_length]
        long_name = 'a' * (max_length + 1)
        validator = described_class.new(name: long_name)
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_NAME_TOO_LONG)
      end

      it 'returns an error if name contains <' do
        validator = described_class.new(name: 'Ingredient <test>')
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_NAME_INVALID_CHARS)
      end

      it 'returns an error if name contains >' do
        validator = described_class.new(name: 'Ingredient >test')
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_NAME_INVALID_CHARS)
      end

      it 'returns an error if name contains "' do
        validator = described_class.new(name: 'Ingredient "test"')
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_NAME_INVALID_CHARS)
      end

      it 'returns an error if name contains \'' do
        validator = described_class.new(name: "Ingredient 'test'")
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_NAME_INVALID_CHARS)
      end

      it 'returns an error if name contains &' do
        validator = described_class.new(name: 'Ingredient & test')
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_NAME_INVALID_CHARS)
      end

      it 'returns multiple errors for a name that is too long with invalid characters' do
        max_length = described_class::CONF[:title_max_length]
        invalid_name = "#{'a' * (max_length + 1)}<>"
        validator = described_class.new(name: invalid_name)
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_NAME_TOO_LONG)
        expect(errors).to include(described_class::ERR_NAME_INVALID_CHARS)
      end

      it 'returns an error if name contains multiple invalid characters' do
        validator = described_class.new(name: 'Test<>"\'&')
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_NAME_INVALID_CHARS)
        expect(errors.count(described_class::ERR_NAME_INVALID_CHARS)).to eq(1)
      end
    end

    context 'with invalid ids' do
      it 'returns an error if there are too many ids' do
        max_ids = described_class::CONF[:max_ingredient_ids]
        too_many_ids = (1..(max_ids + 1)).to_a
        validator = described_class.new(ids: too_many_ids)
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_TOO_MANY_INGREDIENTS)
      end

      it 'returns an error if ids contain letters' do
        validator = described_class.new(ids: [1, 'abc', 3])
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
      end

      it 'returns an error if ids contain special characters' do
        validator = described_class.new(ids: [1, '2@3', 3])
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
      end

      it 'returns an error if ids contain negative numbers' do
        validator = described_class.new(ids: [1, -2, 3])
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
      end

      it 'returns an error if ids contain decimal numbers' do
        validator = described_class.new(ids: [1, '2.5', 3])
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
      end

      it 'returns an error if ids contain empty strings' do
        validator = described_class.new(ids: [1, '', 3])
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
      end

      it 'returns an error if ids contain spaces' do
        validator = described_class.new(ids: [1, '2 3', 4])
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
      end

      it 'returns multiple errors for too many invalid ids' do
        max_ids = described_class::CONF[:max_ingredient_ids]
        invalid_ids = (1..max_ids).to_a + %w[abc def]
        validator = described_class.new(ids: invalid_ids)
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_TOO_MANY_INGREDIENTS)
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
      end

      it 'returns an error if all ids are invalid' do
        validator = described_class.new(ids: %w[abc def xyz])
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
      end
    end

    context 'with multiple combined error types' do
      it 'returns all errors for invalid name and ids' do
        max_length = described_class::CONF[:title_max_length]
        validator = described_class.new(
          name: "#{'a' * (max_length + 1)}<",
          ids: [1, 'invalid', 3]
        )
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_NAME_TOO_LONG)
        expect(errors).to include(described_class::ERR_NAME_INVALID_CHARS)
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
        expect(errors.length).to eq(3)
      end

      it 'returns all possible errors simultaneously' do
        max_length = described_class::CONF[:title_max_length]
        max_ids = described_class::CONF[:max_ingredient_ids]
        validator = described_class.new(
          name: "#{'a' * (max_length + 1)}&<>",
          ids: (1..max_ids).to_a + %w[invalid abc]
        )
        success, errors = validator.validate!

        expect(success).to be false
        expect(errors).to include(described_class::ERR_NAME_TOO_LONG)
        expect(errors).to include(described_class::ERR_NAME_INVALID_CHARS)
        expect(errors).to include(described_class::ERR_TOO_MANY_INGREDIENTS)
        expect(errors).to include(described_class::ERR_INVALID_INGREDIENTS)
        expect(errors.length).to eq(4)
      end
    end
  end

  describe '#errors' do
    it 'exposes the errors attribute for reading' do
      validator = described_class.new(name: 'Test')
      expect(validator.errors).to eq([])
    end

    it 'contains errors after validation' do
      validator = described_class.new(name: 'Test <>')
      validator.validate!
      expect(validator.errors).to include(described_class::ERR_NAME_INVALID_CHARS)
    end

    it 'accumulates multiple errors' do
      max_length = described_class::CONF[:title_max_length]
      validator = described_class.new(name: "#{'a' * (max_length + 1)}<")
      validator.validate!
      expect(validator.errors.length).to eq(2)
    end
  end

  describe '#filter_params' do
    it 'exposes the filter_params attribute for reading' do
      params = { name: 'Test', ids: [1, 2] }
      validator = described_class.new(params)
      expect(validator.filter_params).to eq(params)
    end

    it 'preserves the original params structure' do
      params = { name: 'Test', ids: [1, 2, 3] }
      validator = described_class.new(params)
      validator.validate!
      expect(validator.filter_params).to eq(params)
    end
  end

  describe 'private methods' do
    describe '#validate_name_filter' do
      it 'skips validation when name is blank' do
        validator = described_class.new(name: '')
        validator.validate!
        expect(validator.errors).to be_empty
      end
    end

    describe '#validate_ids_filter' do
      it 'skips validation when ids is blank' do
        validator = described_class.new(ids: [])
        validator.validate!
        expect(validator.errors).to be_empty
      end
    end
  end
end
