# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cacheable do
  let(:test_class) do
    Class.new do
      include Cacheable
    end
  end

  before do
    test_class.clear_ingredient_cache
    test_class.clear_recipe_ingredient_cache
  end

  describe '.ingredient_cache' do
    it 'initializes an empty hash on first call' do
      expect(test_class.ingredient_cache).to eq({})
    end

    it 'returns the same instance on every call' do
      cache1 = test_class.ingredient_cache
      cache2 = test_class.ingredient_cache
      expect(cache1.object_id).to eq(cache2.object_id)
    end

    it 'persists added data' do
      test_class.ingredient_cache['test'] = 123
      expect(test_class.ingredient_cache['test']).to eq(123)
    end
  end

  describe '.recipe_ingredient_cache' do
    it 'initializes an empty hash on first call' do
      expect(test_class.recipe_ingredient_cache).to eq({})
    end

    it 'returns the same instance on every call' do
      cache1 = test_class.recipe_ingredient_cache
      cache2 = test_class.recipe_ingredient_cache
      expect(cache1.object_id).to eq(cache2.object_id)
    end
  end

  describe '.clear_ingredient_cache' do
    it 'clears the ingredient cache' do
      test_class.ingredient_cache['test'] = 123
      test_class.clear_ingredient_cache
      expect(test_class.ingredient_cache).to eq({})
    end

    it 'fully reinitializes the cache' do
      old_cache = test_class.ingredient_cache
      test_class.clear_ingredient_cache
      expect(test_class.ingredient_cache.object_id).not_to eq(old_cache.object_id)
    end
  end

  describe '.clear_recipe_ingredient_cache' do
    it 'clears the recipe_ingredient cache' do
      test_class.recipe_ingredient_cache['test_1'] = true
      test_class.clear_recipe_ingredient_cache
      expect(test_class.recipe_ingredient_cache).to eq({})
    end
  end

  describe '.preload_ingredient_cache' do
    let!(:ingredient1) { create(:ingredient, default_name: 'Tomate', id: 1) }
    let!(:ingredient2) { create(:ingredient, default_name: 'Carotte', id: 2) }
    let!(:ingredient3) { create(:ingredient, default_name: 'POMME', id: 3) }

    it 'loads all ingredients into the cache' do
      test_class.preload_ingredient_cache

      expect(test_class.ingredient_cache).to include(
        'tomate' => 1,
        'carotte' => 2,
        'pomme' => 3
      )
    end

    it 'transforms keys to lowercase' do
      test_class.preload_ingredient_cache

      expect(test_class.ingredient_cache.keys).to all(match(/^[a-z]+$/))
    end

    it 'merges with existing cache data' do
      test_class.ingredient_cache['existing'] = 99
      test_class.preload_ingredient_cache

      expect(test_class.ingredient_cache['existing']).to eq(99)
      expect(test_class.ingredient_cache['tomate']).to eq(1)
    end

    it 'calls Ingredient.pluck with the correct parameters' do
      expect(Ingredient).to receive(:pluck).with(:default_name, :id).and_return([])
      test_class.preload_ingredient_cache
    end
  end

  describe '.preload_recipe_ingredient_cache' do
    let!(:ingredient1) { create(:ingredient, id: 1) }
    let!(:ingredient2) { create(:ingredient, id: 2) }
    let!(:ri1) { create(:recipe_ingredient, default_name: 'Tomate', ingredient: ingredient1) }
    let!(:ri2) { create(:recipe_ingredient, default_name: 'Carotte', ingredient: ingredient2) }

    it 'loads all recipe_ingredients into the cache' do
      test_class.preload_recipe_ingredient_cache

      expect(test_class.recipe_ingredient_cache).to include(
        'Tomate_1' => true,
        'Carotte_2' => true
      )
    end

    it 'uses the cache_key format correctly' do
      test_class.preload_recipe_ingredient_cache

      test_class.recipe_ingredient_cache.keys.each do |key|
        expect(key).to match(/^.+_\d+$/)
      end
    end

    it 'calls RecipeIngredient.pluck with the correct parameters' do
      expect(RecipeIngredient).to receive(:pluck)
        .with(:default_name, :ingredient_id)
        .and_return([])

      test_class.preload_recipe_ingredient_cache
    end
  end

  describe '.cache_ingredients!' do
    let!(:ingredient1) { create(:ingredient, default_name: 'Tomate', id: 1) }
    let!(:ingredient2) { create(:ingredient, default_name: 'Carotte', id: 2) }
    let!(:ingredient3) { create(:ingredient, default_name: 'Poivron', id: 3) }

    it 'caches only the specified ingredients' do
      test_class.cache_ingredients!(['Tomate', 'Carotte'])

      expect(test_class.ingredient_cache).to include(
        'tomate' => 1,
        'carotte' => 2
      )
      expect(test_class.ingredient_cache).not_to have_key('poivron')
    end

    it 'transforms keys to lowercase' do
      test_class.cache_ingredients!(['Tomate'])

      expect(test_class.ingredient_cache).to have_key('tomate')
    end

    it 'merges with existing cache' do
      test_class.ingredient_cache['existing'] = 99
      test_class.cache_ingredients!(['Tomate'])

      expect(test_class.ingredient_cache['existing']).to eq(99)
      expect(test_class.ingredient_cache['tomate']).to eq(1)
    end

    it 'performs a filtered query by names' do
      expect(Ingredient).to receive(:where).with(default_name: ['Tomate']).and_call_original
      test_class.cache_ingredients!(['Tomate'])
    end

    it 'handles an empty array' do
      expect { test_class.cache_ingredients!([]) }.not_to raise_error
      expect(test_class.ingredient_cache).to eq({})
    end
  end

  describe '.cached_ingredient_id' do
    before do
      test_class.ingredient_cache['tomate'] = 1
      test_class.ingredient_cache['carotte'] = 2
    end

    it 'returns the cached ingredient id' do
      expect(test_class.cached_ingredient_id('tomate')).to eq(1)
    end

    it 'handles uppercase names' do
      expect(test_class.cached_ingredient_id('TOMATE')).to eq(1)
    end

    it 'handles mixed-case names' do
      expect(test_class.cached_ingredient_id('ToMaTe')).to eq(1)
    end

    it 'returns nil if the ingredient is not in cache' do
      expect(test_class.cached_ingredient_id('missing')).to be_nil
    end

    it 'returns nil for an empty string' do
      expect(test_class.cached_ingredient_id('')).to be_nil
    end
  end

  describe '.recipe_ingredient_exists?' do
    before do
      test_class.recipe_ingredient_cache['tomate_1'] = true
      test_class.recipe_ingredient_cache['carotte_2'] = true
    end

    it 'returns true if the key exists' do
      expect(test_class.recipe_ingredient_exists?('tomate_1')).to be true
    end

    it 'returns nil if the key does not exist' do
      expect(test_class.recipe_ingredient_exists?('missing_99')).to be_nil
    end

    it 'is case-sensitive' do
      expect(test_class.recipe_ingredient_exists?('Tomate_1')).to be_nil
    end
  end

  describe '.mark_recipe_ingredient_cached' do
    it 'adds an entry to the cache' do
      test_class.mark_recipe_ingredient_cached('new_key_1')

      expect(test_class.recipe_ingredient_cache['new_key_1']).to be true
    end

    it 'overwrites an existing value' do
      test_class.recipe_ingredient_cache['key_1'] = false
      test_class.mark_recipe_ingredient_cached('key_1')

      expect(test_class.recipe_ingredient_cache['key_1']).to be true
    end

    it 'accepts any string key' do
      test_class.mark_recipe_ingredient_cached('complex_key_123_abc')

      expect(test_class.recipe_ingredient_cache['complex_key_123_abc']).to be true
    end
  end

  describe 'full integration' do
    let!(:tomate) { create(:ingredient, default_name: 'Tomate', id: 1) }
    let!(:carotte) { create(:ingredient, default_name: 'Carotte', id: 2) }
    let!(:ri1) { create(:recipe_ingredient, default_name: 'Tomate', ingredient: tomate) }

    it 'supports a full cache workflow' do
      test_class.preload_ingredient_cache
      test_class.preload_recipe_ingredient_cache

      expect(test_class.cached_ingredient_id('tomate')).to eq(1)
      expect(test_class.recipe_ingredient_exists?('Tomate_1')).to be true

      test_class.mark_recipe_ingredient_cached('Carotte_2')
      expect(test_class.recipe_ingredient_exists?('Carotte_2')).to be true

      test_class.clear_ingredient_cache
      test_class.clear_recipe_ingredient_cache

      expect(test_class.ingredient_cache).to be_empty
      expect(test_class.recipe_ingredient_cache).to be_empty
    end
  end
end
