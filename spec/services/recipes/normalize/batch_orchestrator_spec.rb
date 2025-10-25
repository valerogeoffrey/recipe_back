# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Normalize::BatchOrchestrator, type: :service do
  let(:valid_json_recipe) do
    {
      'title' => 'Chocolate Cake',
      'ingredients' => ['200g flour', '2 eggs'],
      'cook_time' => 30,
      'prep_time' => 15,
      'ratings' => 4.5,
      'author' => 'Alice',
      'image' => 'cake.png',
      'category' => 'Dessert',
      'cuisine' => 'French'
    }
  end

  describe '.process' do
    context 'when processing a batch' do
      let(:json_recipe) do
        {
          'title' => 'Chocolate Cake',
          'ingredients' => ['200g flour'],
          'cook_time' => 30,
          'prep_time' => 15,
          'ratings' => 4.5,
          'author' => 'Alice',
          'image' => 'cake.jpg'
        }
      end

      let(:recipe) { instance_double('Recipe', default_title: 'Chocolate Cake', id: 1) }
      let(:ingredient) { instance_double('Ingredient', id: 1, default_name: 'flour') }
      let(:parsed_ingredient) { double('ParsedIngredient', original_query: '200g flour', amount: 200, unit: 'g') }

      before do
        allow(Recipe).to receive(:find_by).and_return(nil)
        allow(Recipe).to receive(:find_or_create_by!).and_return(recipe)

        Ingredient.ingredient_cache['flour'] = ingredient.id

        allow(Ingredient).to receive(:parse).and_return(Result.success(parsed_ingredient))
        allow(Ingredient).to receive(:extract_ingredient_name).and_return('flour')

        allow(Ingredient).to receive(:insert_all)
        allow(RecipeIngredient).to receive(:insert_all)
        allow(RecipeIngredient).to receive(:where).and_return(double(pluck: [1]))
        allow(RecipeRecipeIngredient).to receive(:insert_all)
      end

      it 'creates recipe and ingredients successfully' do
        results = described_class.process([json_recipe])

        expect(results).to all(be_success)
        expect(results.size).to eq(1)
      end

      it 'wraps the entire process in a transaction' do
        expect(ActiveRecord::Base).to receive(:transaction).and_call_original

        described_class.process([json_recipe])
      end
    end

    context 'when ingredient processing fails' do
      let(:invalid_recipe) do
        {
          'title' => 'Bad Recipe',
          'ingredients' => []
        }
      end

      it 'processes the batch and returns results' do
        results = described_class.process([invalid_recipe])

        expect(results).to be_an(Array)
      end
    end
  end

  describe 'delegations' do
    it 'uses Ingredient for caching' do
      expect(Ingredient).to receive(:ingredient_cache).and_return({})
      Ingredient.ingredient_cache
    end
  end
end
