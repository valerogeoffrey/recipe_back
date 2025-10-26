# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkInsertable do
  before do
    allow(Ingredient).to receive(:insert_all)
    allow(Ingredient).to receive(:ingredient_id).and_return(nil)
    allow(Ingredient).to receive(:extract_quantity) { |parsed| parsed[:quantity] }
    allow(Ingredient).to receive(:extract_amount) { |parsed| parsed[:amount] }
    allow(Ingredient).to receive(:extract_unit) { |parsed| parsed[:unit] }

    allow(RecipeIngredient).to receive(:insert_all)
    allow(RecipeIngredient).to receive(:where).and_return(double(pluck: []))
    allow(RecipeIngredient).to receive(:recipe_ingredient_exists?).and_return(false)

    allow(RecipeRecipeIngredient).to receive(:insert_all)
  end

  describe '.bulk_create_ingredients' do
    let(:current_time) { Time.current }

    before do
      allow(Time).to receive(:current).and_return(current_time)
    end

    it 'prepares records with correct structure' do
      names = %w[Tomato Carrot Onion]
      expected_records = [
        { default_name: 'Tomato', created_at: current_time, updated_at: current_time },
        { default_name: 'Carrot', created_at: current_time, updated_at: current_time },
        { default_name: 'Onion', created_at: current_time, updated_at: current_time }
      ]

      Ingredient.bulk_create_ingredients(names)

      expect(Ingredient).to have_received(:insert_all).with(expected_records, unique_by: :default_name)
    end
  end

  describe '.bulk_create_recipe_ingredients' do
    let(:recipe_id) { 123 }
    let(:current_time) { Time.current }

    before do
      allow(Time).to receive(:current).and_return(current_time)
      allow(Ingredient).to receive(:ingredient_id).with('Tomato').and_return(1)
    end

    it 'prepares recipe ingredients with correct structure' do
      data = [{
        ingredient_name: 'Tomato',
        original: '2 large tomatoes',
        parsed: { quantity: '2', amount: 2.0, unit: 'large' }
      }]

      expected_records = [{
        default_name: '2 large tomatoes',
        ingredient_id: 1,
        default_quantity: '2',
        quantity_value: 2.0,
        unit: 'large',
        created_at: current_time,
        updated_at: current_time
      }]

      allow(RecipeIngredient).to receive(:where).and_return(double(pluck: [10]))

      RecipeIngredient.bulk_create_recipe_ingredients(recipe_id, data)

      expect(RecipeIngredient).to have_received(:insert_all).with(expected_records)
    end
  end
end
