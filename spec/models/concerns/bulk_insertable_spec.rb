# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkInsertable do
  let(:ingredient_class) do
    Class.new do
      include BulkInsertable
      include Cacheable

      def self.name
        'Ingredient'
      end

      def self.insert_all(records, options = {})
        records
      end

      def self.extract_quantity(parsed)
        parsed[:quantity]
      end

      def self.extract_amount(parsed)
        parsed[:amount]
      end

      def self.extract_unit(parsed)
        parsed[:unit]
      end
    end
  end

  let(:recipe_ingredient_class) do
    Class.new do
      include BulkInsertable
      include Cacheable

      def self.name
        'RecipeIngredient'
      end

      def self.insert_all(records)
        records
      end

      def self.where(conditions)
        double(pluck: [])
      end
    end
  end

  let(:recipe_recipe_ingredient_class) do
    Class.new do
      def self.insert_all(records)
        records
      end
    end
  end

  before do
    stub_const('Ingredient', ingredient_class)
    stub_const('RecipeIngredient', recipe_ingredient_class)
    stub_const('RecipeRecipeIngredient', recipe_recipe_ingredient_class)

    Ingredient.clear_ingredient_cache
    RecipeIngredient.clear_recipe_ingredient_cache
  end

  describe '.bulk_create_ingredients' do
    let(:current_time) { Time.current }

    before do
      allow(Time).to receive(:current).and_return(current_time)
      allow(Ingredient).to receive(:insert_all)
      allow(Ingredient).to receive(:cache_ingredients!)
    end

    context 'when all names are new' do
      let(:names) { ['Tomato', 'Carrot', 'Onion'] }

      it 'filters out names already in cache' do
        Ingredient.ingredient_cache['tomato'] = 1

        Ingredient.bulk_create_ingredients(names)

        expect(Ingredient).to have_received(:insert_all).with(
          array_including(
            hash_including(default_name: 'Carrot'),
            hash_including(default_name: 'Onion')
          ),
          unique_by: :default_name
        )
      end

      it 'prepares records with correct structure' do
        expected_records = [
          { default_name: 'Tomato', created_at: current_time, updated_at: current_time },
          { default_name: 'Carrot', created_at: current_time, updated_at: current_time },
          { default_name: 'Onion', created_at: current_time, updated_at: current_time }
        ]

        Ingredient.bulk_create_ingredients(names)

        expect(Ingredient).to have_received(:insert_all).with(expected_records, unique_by: :default_name)
        expect(Ingredient).to have_received(:cache_ingredients!).with(names)
      end

      it 'caches ingredients after insertion' do
        Ingredient.bulk_create_ingredients(names)

        expect(Ingredient).to have_received(:cache_ingredients!).with(names)
      end

      it 'uses unique_by constraint on default_name' do
        Ingredient.bulk_create_ingredients(names)

        expect(Ingredient).to have_received(:insert_all).with(anything, unique_by: :default_name)
      end
    end

    context 'when handling empty or nil names' do
      before do
        allow(Ingredient).to receive(:insert_all)
        allow(Ingredient).to receive(:cache_ingredients!)
      end

      it 'filters out empty strings' do
        names = ['Tomato', '', 'Carrot']

        Ingredient.bulk_create_ingredients(names)

        expect(Ingredient).to have_received(:insert_all).with(
          match([
            hash_including(default_name: 'Tomato'),
            hash_including(default_name: 'Carrot')
          ]),
          unique_by: :default_name
        )
      end

      it 'filters out nil values' do
        names = ['Tomato', nil, 'Carrot']

        Ingredient.bulk_create_ingredients(names)

        expect(Ingredient).to have_received(:insert_all).with(
          match([
            hash_including(default_name: 'Tomato'),
            hash_including(default_name: 'Carrot')
          ]),
          unique_by: :default_name
        )
      end

      it 'returns early if all names are blank' do
        names = ['', nil, '   ']

        Ingredient.bulk_create_ingredients(names)

        expect(Ingredient).not_to have_received(:insert_all)
        expect(Ingredient).not_to have_received(:cache_ingredients!)
      end
    end

    context 'when all names are already cached' do
      before do
        allow(Ingredient).to receive(:insert_all)
        allow(Ingredient).to receive(:cache_ingredients!)
      end

      it 'returns early without inserting' do
        names = ['Tomato', 'Carrot']
        Ingredient.ingredient_cache['tomato'] = 1
        Ingredient.ingredient_cache['carrot'] = 2

        Ingredient.bulk_create_ingredients(names)

        expect(Ingredient).not_to have_received(:insert_all)
        expect(Ingredient).not_to have_received(:cache_ingredients!)
      end
    end

    context 'when handling duplicates' do
      it 'catches RecordNotUnique and caches ingredients anyway' do
        names = ['Tomato']
        error = ActiveRecord::RecordNotUnique.new('duplicate key')

        allow(Ingredient).to receive(:insert_all).and_raise(error)
        allow(Ingredient).to receive(:cache_ingredients!)
        allow(Rails.logger).to receive(:warn)

        Ingredient.bulk_create_ingredients(names)

        expect(Ingredient).to have_received(:cache_ingredients!).with(names)
        expect(Rails.logger).to have_received(:warn).with("[DUPLICATE] Ingredient duplicate: #{error.message}")
      end

      it 'logs warning with error message' do
        names = ['Tomato']
        error = ActiveRecord::RecordNotUnique.new('unique constraint violated')

        allow(Ingredient).to receive(:insert_all).and_raise(error)
        allow(Ingredient).to receive(:cache_ingredients!)
        allow(Rails.logger).to receive(:warn)

        Ingredient.bulk_create_ingredients(names)

        expect(Rails.logger).to have_received(:warn).with('[DUPLICATE] Ingredient duplicate: unique constraint violated')
      end
    end

    context 'with empty input' do
      before do
        allow(Ingredient).to receive(:insert_all)
        allow(Ingredient).to receive(:cache_ingredients!)
      end

      it 'returns early without any operations' do
        Ingredient.bulk_create_ingredients([])

        expect(Ingredient).not_to have_received(:insert_all)
        expect(Ingredient).not_to have_received(:cache_ingredients!)
      end
    end
  end

  describe '.bulk_create_recipe_ingredients' do
    let(:recipe_id) { 123 }
    let(:current_time) { Time.current }

    before do
      allow(Time).to receive(:current).and_return(current_time)
      allow(RecipeIngredient).to receive(:insert_all)
      allow(RecipeIngredient).to receive(:mark_recipe_ingredient_cached)
      allow(RecipeRecipeIngredient).to receive(:insert_all)

      Ingredient.ingredient_cache['tomato'] = 1
      Ingredient.ingredient_cache['carrot'] = 2
    end

    context 'with valid recipe ingredients data' do
      let(:recipe_ingredients_data) do
        [
          {
            ingredient_name: 'Tomato',
            original: '2 large tomatoes',
            parsed: { quantity: '2', amount: 2.0, unit: 'large' }
          },
          {
            ingredient_name: 'Carrot',
            original: '3 carrots',
            parsed: { quantity: '3', amount: 3.0, unit: nil }
          }
        ]
      end

      it 'prepares recipe ingredients with correct structure' do
        expected_records = [
          {
            default_name: '2 large tomatoes',
            ingredient_id: 1,
            default_quantity: '2',
            quantity_value: 2.0,
            unit: 'large',
            created_at: current_time,
            updated_at: current_time
          },
          {
            default_name: '3 carrots',
            ingredient_id: 2,
            default_quantity: '3',
            quantity_value: 3.0,
            unit: :unit,
            created_at: current_time,
            updated_at: current_time
          }
        ]

        allow(RecipeIngredient).to receive(:where).and_return(double(pluck: [10, 11]))

        RecipeIngredient.bulk_create_recipe_ingredients(recipe_id, recipe_ingredients_data)

        expect(RecipeIngredient).to have_received(:insert_all).with(expected_records)
      end

      it 'defaults unit to :unit when unit is nil' do
        data = [{
          ingredient_name: 'Tomato',
          original: 'tomatoes',
          parsed: { quantity: '2', amount: 2.0, unit: nil }
        }]

        allow(RecipeIngredient).to receive(:where).and_return(double(pluck: [10]))

        RecipeIngredient.bulk_create_recipe_ingredients(recipe_id, data)

        expect(RecipeIngredient).to have_received(:insert_all).with(
          array_including(hash_including(unit: :unit))
        )
      end

      it 'marks recipe ingredients as cached' do
        allow(RecipeIngredient).to receive(:where).and_return(double(pluck: [10, 11]))

        RecipeIngredient.bulk_create_recipe_ingredients(recipe_id, recipe_ingredients_data)

        expect(RecipeIngredient).to have_received(:mark_recipe_ingredient_cached).with('2 large tomatoes_1')
        expect(RecipeIngredient).to have_received(:mark_recipe_ingredient_cached).with('3 carrots_2')
      end

      it 'creates recipe_recipe_ingredients associations' do
        where_double = double
        allow(RecipeIngredient).to receive(:where)
          .with(default_name: ['2 large tomatoes', '3 carrots'])
          .and_return(where_double)
        allow(where_double).to receive(:pluck).with(:id).and_return([10, 11])

        expected_rri = [
          { recipe_id: 123, recipe_ingredient_id: 10, created_at: current_time, updated_at: current_time },
          { recipe_id: 123, recipe_ingredient_id: 11, created_at: current_time, updated_at: current_time }
        ]

        RecipeIngredient.bulk_create_recipe_ingredients(recipe_id, recipe_ingredients_data)

        expect(RecipeRecipeIngredient).to have_received(:insert_all).with(expected_rri)
      end
    end

    context 'when ingredient is not in cache' do
      it 'logs critical error and skips the ingredient' do
        data = [{
          ingredient_name: 'UnknownIngredient',
          original: '1 unknown',
          parsed: { quantity: '1', amount: 1.0, unit: 'piece' }
        }]

        allow(RecipeIngredient).to receive(:where).and_return(double(pluck: []))
        allow(Rails.logger).to receive(:error)

        RecipeIngredient.bulk_create_recipe_ingredients(recipe_id, data)

        expect(Rails.logger).to have_received(:error).with("[CRITICAL] Ingredient 'UnknownIngredient' not in cache")
        expect(RecipeIngredient).not_to have_received(:insert_all)
      end

      it 'continues processing other valid ingredients' do
        data = [
          { ingredient_name: 'UnknownIngredient', original: '1 unknown', parsed: { quantity: '1', amount: 1.0, unit: nil } },
          { ingredient_name: 'Tomato', original: '2 tomatoes', parsed: { quantity: '2', amount: 2.0, unit: nil } }
        ]

        allow(Rails.logger).to receive(:error)
        allow(RecipeIngredient).to receive(:where).and_return(double(pluck: [10]))

        RecipeIngredient.bulk_create_recipe_ingredients(recipe_id, data)

        expect(RecipeIngredient).to have_received(:insert_all).with(
          match([hash_including(default_name: '2 tomatoes')])
        )
      end
    end

    context 'when recipe ingredient already exists in cache' do
      it 'skips ingredients that are already cached' do
        RecipeIngredient.recipe_ingredient_cache['2 large tomatoes_1'] = true

        data = [{
          ingredient_name: 'Tomato',
          original: '2 large tomatoes',
          parsed: { quantity: '2', amount: 2.0, unit: 'large' }
        }]

        allow(RecipeIngredient).to receive(:where).and_return(double(pluck: []))

        RecipeIngredient.bulk_create_recipe_ingredients(recipe_id, data)

        expect(RecipeIngredient).not_to have_received(:insert_all)
      end

      it 'processes only non-cached ingredients' do
        RecipeIngredient.recipe_ingredient_cache['2 large tomatoes_1'] = true

        data = [
          { ingredient_name: 'Tomato', original: '2 large tomatoes', parsed: { quantity: '2', amount: 2.0, unit: nil } },
          { ingredient_name: 'Carrot', original: '3 carrots', parsed: { quantity: '3', amount: 3.0, unit: nil } }
        ]

        allow(RecipeIngredient).to receive(:where).and_return(double(pluck: [11]))

        RecipeIngredient.bulk_create_recipe_ingredients(recipe_id, data)

        expect(RecipeIngredient).to have_received(:insert_all).with(
          match([hash_including(default_name: '3 carrots')])
        )
      end
    end

    context 'with empty input' do
      before do
        allow(RecipeIngredient).to receive(:insert_all)
        allow(RecipeRecipeIngredient).to receive(:insert_all)
      end

      it 'returns early without any operations' do
        RecipeIngredient.bulk_create_recipe_ingredients(recipe_id, [])

        expect(RecipeIngredient).not_to have_received(:insert_all)
        expect(RecipeRecipeIngredient).not_to have_received(:insert_all)
      end
    end

    context 'when no recipe ingredients to insert' do
      it 'does not call insert_all for recipe ingredients' do
        RecipeIngredient.recipe_ingredient_cache['2 large tomatoes_1'] = true

        data = [{
          ingredient_name: 'Tomato',
          original: '2 large tomatoes',
          parsed: { quantity: '2', amount: 2.0, unit: 'large' }
        }]

        allow(RecipeIngredient).to receive(:where).and_return(double(pluck: []))

        RecipeIngredient.bulk_create_recipe_ingredients(recipe_id, data)

        expect(RecipeIngredient).not_to have_received(:insert_all)
        expect(RecipeRecipeIngredient).not_to have_received(:insert_all)
      end
    end

    context 'when RecipeIngredient.where returns no IDs' do
      it 'does not insert recipe_recipe_ingredients' do
        data = [{
          ingredient_name: 'Tomato',
          original: '2 tomatoes',
          parsed: { quantity: '2', amount: 2.0, unit: nil }
        }]

        allow(RecipeIngredient).to receive(:where).and_return(double(pluck: []))

        RecipeIngredient.bulk_create_recipe_ingredients(recipe_id, data)

        expect(RecipeRecipeIngredient).not_to have_received(:insert_all)
      end
    end
  end
end
