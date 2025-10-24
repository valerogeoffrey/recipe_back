# frozen_string_literal: true

# spec/performances/aggregation_performance_spec.rb
require 'rails_helper'
require 'benchmark'

RSpec.describe 'Aggregation Performance', type: :request do
  before(:all) do
    RecipeRecipeIngredient.delete_all
    RecipeIngredient.delete_all
    Ingredient.delete_all
    Recipe.delete_all

    puts '> Cleanup completed'
    puts '> Creating 1,000 base ingredients...'

    ingredients_data = 1_000.times.map do |i|
      {
        default_name: "Ingredient #{i}",
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    Ingredient.insert_all(ingredients_data)
    ingredient_ids = Ingredient.pluck(:id)
    puts "✓ #{ingredient_ids.size} ingredients created"

    # 20,000 recipes × 5 ingredients = 100,000 recipe_ingredients
    puts '> Creating 100,000 recipe_ingredients...'

    recipe_ingredients_data = []
    100_000.times do |i|
      recipe_ingredients_data << {
        default_name: "Recipe Ingredient #{i}",
        ingredient_id: ingredient_ids.sample,
        quantity_value: rand(1.0..500.0).round(2),
        default_quantity: rand(1.0..500.0).round(2),
        unit: %w[g kg ml l pcs tbsp tsp cup].sample,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    recipe_ingredients_data.each_slice(10_000) do |batch|
      RecipeIngredient.insert_all(batch)
    end

    recipe_ingredient_ids = RecipeIngredient.pluck(:id)
    puts "✓ #{recipe_ingredient_ids.size} recipe_ingredients created"

    recipe_count = recipe_ingredient_ids.size / 5
    puts "> Creating #{recipe_count} recipes..."

    recipes_data = recipe_count.times.map do |i|
      {
        default_title: "Recipe_#{i}",
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    recipes_data.each_slice(5_000) do |batch|
      Recipe.insert_all(batch)
    end

    recipe_ids = Recipe.pluck(:id)
    puts "✓ #{recipe_ids.size} recipes created"

    puts "> Creating #{recipe_ingredient_ids.size} links..."

    pivot_data = []
    recipe_ids.each_with_index do |recipe_id, idx|
      start_idx = idx * 5
      end_idx = start_idx + 4
      next if start_idx >= recipe_ingredient_ids.size

      slice = recipe_ingredient_ids[start_idx..end_idx]
      next if slice.blank?

      slice.compact.each do |ri_id|
        pivot_data << {
          recipe_id: recipe_id,
          recipe_ingredient_id: ri_id,
          created_at: Time.current,
          updated_at: Time.current
        }
      end
    end

    pivot_data.each_slice(10_000) do |batch|
      RecipeRecipeIngredient.insert_all(batch)
    end

    puts "✓ #{RecipeRecipeIngredient.count} links created"
    puts "\n> Setup: #{Recipe.count} recipes with #{RecipeRecipeIngredient.count} links\n\n"
  end

  after(:all) do
    RecipeRecipeIngredient.delete_all
    RecipeIngredient.delete_all
    Ingredient.delete_all
    Recipe.delete_all
  end

  describe 'Test 1: Aggregation WITHOUT LIMIT (all recipes)' do
    it 'compares performance on ALL recipes' do
      Rails.cache.clear

      # Without cache - ALL recipes
      time_without = Benchmark.realtime do
        Recipe.joins(recipe_recipe_ingredients: { recipe_ingredient: :ingredient })
              .group('recipes.id')
              .select('recipes.id,
                       SUM(recipe_ingredients.quantity_value) as total_quantity,
                       COUNT(DISTINCT ingredients.id) as ingredient_count')
              .to_a
      end

      # With cache - store hashes instead of AR objects
      cache_key = 'all_recipe_aggregations'
      Rails.cache.delete(cache_key)

      time_with_miss = Benchmark.realtime do
        Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          Recipe.joins(recipe_recipe_ingredients: { recipe_ingredient: :ingredient })
                .group('recipes.id')
                .select('recipes.id,
                         SUM(recipe_ingredients.quantity_value) as total_quantity,
                         COUNT(DISTINCT ingredients.id) as ingredient_count')
                .map { |r| { id: r.id, total_quantity: r.total_quantity.to_f, ingredient_count: r.ingredient_count } }
        end
      end

      time_with_hit = Benchmark.realtime do
        Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          Recipe.joins(recipe_recipe_ingredients: { recipe_ingredient: :ingredient })
                .group('recipes.id')
                .select('recipes.id,
                         SUM(recipe_ingredients.quantity_value) as total_quantity,
                         COUNT(DISTINCT ingredients.id) as ingredient_count')
                .map { |r| { id: r.id, total_quantity: r.total_quantity.to_f, ingredient_count: r.ingredient_count } }
        end
      end

      improvement = (time_without / time_with_hit).round(1)

      puts "\n📊 Test 1: Aggregation of ALL recipes (#{Recipe.count})"
      puts "  Without cache: #{(time_without * 1000).round(2)}ms"
      puts "  Cache miss: #{(time_with_miss * 1000).round(2)}ms"
      puts "  Cache hit: #{(time_with_hit * 1000).round(2)}ms"
      puts "  🚀 Improvement: #{improvement}x faster\n"

      expect(improvement).to be > 10
    end
  end

  describe 'Test 2: Repeated queries (autocomplete simulation)' do
    it 'simulates 100 repeated calls' do
      Rails.cache.clear

      search_queries = %w[Recipe_1 Recipe_10 Recipe_100 Recipe_1000] * 25 # 100 queries

      # Without cache
      time_without = Benchmark.realtime do
        search_queries.each do |query|
          Recipe.where('default_title LIKE ?', "#{query}%")
                .joins(recipe_recipe_ingredients: { recipe_ingredient: :ingredient })
                .group('recipes.id')
                .select('recipes.*,
                         SUM(recipe_ingredients.quantity_value) as total_quantity')
                .limit(10)
                .to_a
        end
      end

      # With cache - store simple hashes
      time_with = Benchmark.realtime do
        search_queries.each do |query|
          cache_key = "search_#{query}"
          Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
            Recipe.where('default_title LIKE ?', "#{query}%")
                  .joins(recipe_recipe_ingredients: { recipe_ingredient: :ingredient })
                  .group('recipes.id')
                  .select('recipes.*,
                           SUM(recipe_ingredients.quantity_value) as total_quantity')
                  .limit(10)
                  .map { |r| { id: r.id, title: r.default_title, total_quantity: r.total_quantity.to_f } }
          end
        end
      end

      improvement = (time_without / time_with).round(1)

      puts "\n📊 Test 2: 100 repeated search queries"
      puts "  Without cache: #{(time_without * 1000).round(2)}ms"
      puts "  With cache: #{(time_with * 1000).round(2)}ms"
      puts "  🚀 Improvement: #{improvement}x faster\n"

      expect(improvement).to be > 2
    end
  end

  describe 'Test 3: Complex aggregation by unit' do
    it 'groups by unit across all recipes' do
      Rails.cache.clear

      # Complex query without cache
      time_without = Benchmark.realtime do
        Recipe.joins(recipe_recipe_ingredients: :recipe_ingredient)
              .group('recipe_ingredients.unit')
              .select('recipe_ingredients.unit,
                       COUNT(DISTINCT recipes.id) as recipe_count,
                       SUM(recipe_ingredients.quantity_value) as total_quantity,
                       AVG(recipe_ingredients.quantity_value) as avg_quantity')
              .to_a
      end

      # With cache - store simple hashes
      cache_key = 'units_global_stats'
      Rails.cache.delete(cache_key)

      time_with_miss = Benchmark.realtime do
        Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
          Recipe.joins(recipe_recipe_ingredients: :recipe_ingredient)
                .group('recipe_ingredients.unit')
                .select('recipe_ingredients.unit,
                         COUNT(DISTINCT recipes.id) as recipe_count,
                         SUM(recipe_ingredients.quantity_value) as total_quantity,
                         AVG(recipe_ingredients.quantity_value) as avg_quantity')
                .map { |r| { unit: r.unit, recipe_count: r.recipe_count, total_quantity: r.total_quantity.to_f, avg_quantity: r.avg_quantity.to_f } }
        end
      end

      time_with_hit = Benchmark.realtime do
        Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
          Recipe.joins(recipe_recipe_ingredients: :recipe_ingredient)
                .group('recipe_ingredients.unit')
                .select('recipe_ingredients.unit,
                         COUNT(DISTINCT recipes.id) as recipe_count,
                         SUM(recipe_ingredients.quantity_value) as total_quantity,
                         AVG(recipe_ingredients.quantity_value) as avg_quantity')
                .map { |r| { unit: r.unit, recipe_count: r.recipe_count, total_quantity: r.total_quantity.to_f, avg_quantity: r.avg_quantity.to_f } }
        end
      end

      improvement = (time_without / time_with_hit).round(1)

      puts "\n📊 Test 3: Global statistics by unit"
      puts "  Without cache: #{(time_without * 1000).round(2)}ms"
      puts "  Cache miss: #{(time_with_miss * 1000).round(2)}ms"
      puts "  Cache hit: #{(time_with_hit * 1000).round(2)}ms"
      puts "  🚀 Improvement: #{improvement}x faster\n"
    end
  end
end
