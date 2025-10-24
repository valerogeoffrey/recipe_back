# frozen_string_literal: true

module Cacheable
  extend ActiveSupport::Concern

  class_methods do
    def ingredient_cache
      @ingredient_cache ||= {}
    end

    def recipe_ingredient_cache
      @recipe_ingredient_cache ||= {}
    end

    def clear_ingredient_cache
      @ingredient_cache = {}
    end

    def clear_recipe_ingredient_cache
      @recipe_ingredient_cache = {}
    end

    def preload_ingredient_cache
      ingredient_cache.merge!(
        Ingredient.pluck(:default_name, :id)
                  .to_h
                  .transform_keys(&:downcase)
      )
    end

    def preload_recipe_ingredient_cache
      RecipeIngredient.pluck(:default_name, :ingredient_id).each do |name, ing_id|
        cache_key = "#{name}_#{ing_id}"
        recipe_ingredient_cache[cache_key] = true
      end
    end

    def cache_ingredients!(names)
      ingredient_cache.merge!(
        Ingredient.where(default_name: names)
                  .pluck(:default_name, :id)
                  .to_h.transform_keys(&:downcase)
      )
    end

    def cached_ingredient_id(name)
      ingredient_cache[name.downcase]
    end

    def recipe_ingredient_exists?(cache_key)
      recipe_ingredient_cache[cache_key]
    end

    def mark_recipe_ingredient_cached(cache_key)
      recipe_ingredient_cache[cache_key] = true
    end
  end
end
