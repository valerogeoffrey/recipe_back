# frozen_string_literal: true

# spec/requests/api/v1/recipes_spec.rb
require 'rails_helper'

RSpec.describe 'Api::V1::Recipes', type: :request do
  before do
    allow_any_instance_of(RequestCacheable).to receive(:cache_fetch) { |_, &block| block.call }
  end

  describe 'GET /api/v1/recipes' do
    let!(:egg) do
      create(
        :ingredient,
        default_name: 'Egg'
      )
    end

    let!(:flour) do
      create(
        :ingredient,
        default_name: 'Flour'
      )
    end

    let!(:tiramisu) do
      create(
        :recipe,
        prep_time: 10,
        cook_time: 0,
        rating: 4.5,
        default_title: 'Tiramisu'
      )
    end

    let!(:pancakes) do
      create(
        :recipe,
        prep_time: 5,
        cook_time: 10,
        rating: 4.0,
        default_title: 'Pancakes'
      )
    end

    let(:body) { response.parsed_body }

    context 'without filters' do
      it 'returns all recipes' do
        get '/api/v1/recipes'
        expect(response).to have_http_status(:ok)
        expect(body['recipes'].size).to eq(2)
      end
    end

    context 'with title filter' do
      it 'returns only matching recipe' do
        get '/api/v1/recipes', params: { filter: { title: 'Tiramisu' } }
        expect(body['recipes'].size).to eq(1)
        expect(body['recipes'].first['title']).to eq('Tiramisu')
      end
    end

    context 'with ingredient filter' do
      let(:other_ingredient) do
        create(
          :ingredient,
          default_name: 'Other'
        )
      end
      let!(:other_recipe) do
        create(
          :recipe,
          prep_time: 10,
          cook_time: 0,
          rating: 4.5,
          default_title: 'Other_recipe'
        )
      end

      before do
        create(:recipe_ingredient, default_name: '4 big eggs', recipes: [tiramisu], ingredient: egg)
        create(:recipe_ingredient, default_name: '1 flour bag', recipes: [tiramisu], ingredient: flour)
        create(:recipe_ingredient,  default_name: '1/2 flour bag', recipes: [pancakes], ingredient: flour)
        create(:recipe_ingredient,  default_name: 'other ingredient', recipes: [other_recipe], ingredient: other_ingredient)
      end

      it 'returns recipes with all specified ingredients' do
        get '/api/v1/recipes', params: { filter: { ingredient_ids: [egg.id, flour.id] } }
        expect(body['recipes'].pluck('title')).to match_array(%w[Tiramisu Pancakes])
      end
    end

    context 'with sorting' do
      it 'sorts by prep_time descending' do
        get '/api/v1/recipes', params: { sort: { by: 'prep_time_desc' } }

        titles = body['recipes'].pluck('title')
        expect(titles).to eq(%w[Tiramisu Pancakes])
      end

      context 'with relevance sorting' do
        # Test relevance scoring logic which considers:
        # - Match percentage (matched ingredients / total ingredients * 100)
        # - Perfect match bonus (+20 points if recipe has ALL selected ingredients)
        # - Recipe complexity bonus (+10 for ≤5 ingredients, +5 for ≤8 ingredients)
        # - Final relevance score = match_percentage + bonuses
        let!(:milk) do
          create(
            :ingredient,
            default_name: 'Milk'
          )
        end

        let!(:sugar) do
          create(
            :ingredient,
            default_name: 'Sugar'
          )
        end

        let!(:butter) do
          create(
            :ingredient,
            default_name: 'Butter'
          )
        end

        let!(:perfect_recipe) do
          create(
            :recipe,
            prep_time: 15,
            cook_time: 5,
            rating: 4.8,
            default_title: 'Perfect Match Recipe'
          )
        end

        let!(:partial_recipe) do
          create(
            :recipe,
            prep_time: 20,
            cook_time: 10,
            rating: 4.2,
            default_title: 'Partial Match Recipe'
          )
        end

        let!(:complex_recipe) do
          create(
            :recipe,
            prep_time: 30,
            cook_time: 15,
            rating: 4.0,
            default_title: 'Complex Recipe'
          )
        end

        before do
          create(:recipe_ingredient, default_name: '2 eggs for perfect recipe', recipes: [perfect_recipe], ingredient: egg)
          create(:recipe_ingredient, default_name: '1 cup flour for perfect recipe', recipes: [perfect_recipe],
                                     ingredient: flour)
          create(:recipe_ingredient, default_name: '1 cup milk for perfect recipe', recipes: [perfect_recipe],
                                     ingredient: milk)

          create(:recipe_ingredient, default_name: '1 egg for partial recipe', recipes: [partial_recipe], ingredient: egg)
          create(:recipe_ingredient, default_name: '2 cups milk for partial recipe', recipes: [partial_recipe],
                                     ingredient: milk)
          create(:recipe_ingredient, default_name: '1 tsp sugar for partial recipe', recipes: [partial_recipe],
                                     ingredient: sugar)

          create(:recipe_ingredient, default_name: '3 eggs for complex recipe', recipes: [complex_recipe], ingredient: egg)
          create(:recipe_ingredient, default_name: '2 cups flour for complex recipe', recipes: [complex_recipe],
                                     ingredient: flour)
          create(:recipe_ingredient, default_name: '1 cup milk for complex recipe', recipes: [complex_recipe],
                                     ingredient: milk)
          create(:recipe_ingredient, default_name: '1/2 cup sugar for complex recipe', recipes: [complex_recipe],
                                     ingredient: sugar)
          create(:recipe_ingredient, default_name: '1/4 cup butter for complex recipe', recipes: [complex_recipe],
                                     ingredient: butter)

          6.times do |i|
            extra_ingredient = create(:ingredient, default_name: "Extra ingredient #{i} for complex")
            create(:recipe_ingredient, default_name: "1 unit extra #{i} for complex recipe",
                                       recipes: [complex_recipe], ingredient: extra_ingredient)
          end
        end

        it 'sorts by relevance descending when filtering by ingredients' do
          get '/api/v1/recipes', params: {
            filter: { ingredient_ids: [egg.id, flour.id] },
            sort: { by: 'relevance_desc' }
          }

          titles = body['recipes'].pluck('title')

          # Expected order based on relevance scoring:
          # 1. Perfect Match Recipe: 66.7% match + 20 (perfect match) + 10 (≤5 ingredients) = ~96.7 points
          # 2. Partial Match Recipe: 33.3% match + 0 (no perfect match) + 10 (≤5 ingredients) = ~43.3 points
          # 3. Complex Recipe: 18.2% match + 20 (perfect match) + 0 (>8 ingredients) = ~38.2 points
          expect(titles).to eq(['Perfect Match Recipe', 'Partial Match Recipe', 'Complex Recipe'])

          expect(body['recipes'].size).to eq(3)
          recipe_titles = body['recipes'].pluck('title')
          expect(recipe_titles).to include('Perfect Match Recipe', 'Complex Recipe', 'Partial Match Recipe')
        end

        it 'sorts by relevance ascending when filtering by ingredients' do
          get '/api/v1/recipes', params: {
            filter: { ingredient_ids: [egg.id, flour.id] },
            sort: { by: 'relevance' }
          }
          titles = body['recipes'].pluck('title')

          expect(titles).to eq(['Complex Recipe', 'Partial Match Recipe', 'Perfect Match Recipe'])
        end

        it 'applies relevance sorting only when ingredient filter is present' do
          get '/api/v1/recipes', params: {
            sort: { by: 'relevance_desc' }
          }

          expect(body['recipes'].size).to be >= 5

          titles = body['recipes'].pluck('title')

          expect(titles).to include('Perfect Match Recipe', 'Complex Recipe', 'Partial Match Recipe',
                                    'Tiramisu', 'Pancakes')
        end

        it 'combines relevance with match percentage in sorting' do
          get '/api/v1/recipes', params: {
            filter: { ingredient_ids: [egg.id] },
            sort: { by: 'relevance_desc' }
          }

          titles = body['recipes'].pluck('title')

          expect(titles.size).to eq(3)
          expect(titles.first(2)).to include('Perfect Match Recipe', 'Partial Match Recipe')
          expect(titles.last).to eq('Complex Recipe')
        end
      end
    end

    context 'with pagination' do
      it 'returns paginated results' do
        get '/api/v1/recipes', params: { pagination: { page: 1, per_page: 1 } }

        expect(body['recipes'].size).to eq(1)

        get '/api/v1/recipes', params: { pagination: { page: 1, per_page: 2 } }
        body = response.parsed_body
        expect(body['recipes'].size).to eq(2)
      end
    end
  end
end
