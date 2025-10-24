# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Normalize do
  describe 'Errors module' do
    describe 'constants' do
      it 'defines SUCCESS' do
        expect(described_class::Errors::SUCCESS).to eq(:success)
      end

      it 'defines INVALID_RECIPE' do
        expect(described_class::Errors::INVALID_RECIPE).to eq(:invalid_recipe)
      end

      it 'defines INGREDIENT_PARSING_FAILED' do
        expect(described_class::Errors::INGREDIENT_PARSING_FAILED).to eq(:ingredient_parsing_failed)
      end

      it 'defines DATABASE_ERROR' do
        expect(described_class::Errors::DATABASE_ERROR).to eq(:database_error)
      end

      it 'defines TRANSLATION_ERROR' do
        expect(described_class::Errors::TRANSLATION_ERROR).to eq(:translation_error)
      end

      it 'defines UNKNOWN_ERROR' do
        expect(described_class::Errors::UNKNOWN_ERROR).to eq(:unknown_error)
      end
    end

    describe 'error types' do
      it 'all errors are symbols' do
        error_constants = described_class::Errors.constants.map do |const|
          described_class::Errors.const_get(const)
        end

        expect(error_constants).to all(be_a(Symbol))
      end

      it 'has unique error values' do
        error_values = described_class::Errors.constants.map do |const|
          described_class::Errors.const_get(const)
        end

        expect(error_values.uniq.size).to eq(error_values.size)
      end
    end
  end

  describe '.call' do
    let(:json_recipes) { [{ name: 'Test Recipe' }] }

    before do
      allow(Recipes::Normalize::Engine).to receive(:process).and_return([])
    end

    it 'calls the Engine instance' do
      described_class.call(json_recipes)

      expect(Recipes::Normalize::Engine).to have_received(:process)
    end

    context 'with multiple recipes' do
      let(:json_recipes) do
        [
          { name: 'Recipe 1', ingredients: ['ingredient 1'] },
          { name: 'Recipe 2', ingredients: ['ingredient 2'] }
        ]
      end

      it 'passes all recipes to Engine' do
        described_class.call(json_recipes)

        expect(Recipes::Normalize::Engine).to have_received(:process)
      end
    end
  end
end
