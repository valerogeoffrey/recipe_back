# frozen_string_literal: true

module Recipes
  module Normalize
    # Lightweight orchestrator for normalizing recipe data from JSON to database
    #
    # STRATEGY:
    # Processes recipes in batches with a 3-phase approach:
    #   1. Create all recipes in the batch
    #   2. Parse all ingredients (accumulate, don't insert yet)
    #   3. Bulk insert ALL ingredients and links in one go
    #
    # This reduces DB queries from ~400/batch to ~103/batch (100 recipes)
    # Trade-off: More memory usage but significantly faster
    #
    # IDEMPOTENT: Skips recipes that already exist with ingredients
    #
    # RESPONSIBILITIES:
    # - Orchestrates the batch processing workflow
    # - Delegates to specialized classes for specific tasks
    # - Manages transaction boundaries
    class BatchOrchestrator
      class << self
        def process(batch)
          results = []
          all_ingredient_names = []
          recipes_with_ingredients = []

          ActiveRecord::Base.transaction do
            # 1: Process each recipe (create + parse ingredients)
            batch.each do |json_recipe|
              orchestrator = RecipeOrchestrator.new(json_recipe)
              result = orchestrator.process(all_ingredient_names, recipes_with_ingredients)
              results << result
            end

            # 2: Bulk insert ALL unique ingredients for the batch
            unique_ingredient_names = all_ingredient_names.uniq
            Ingredient.bulk_create_ingredients(unique_ingredient_names) if unique_ingredient_names.any?

            # 3: Bulk insert ALL recipe_ingredients and links
            recipes_with_ingredients.each do |data|
              RecipeIngredient.bulk_create_recipe_ingredients(
                data[:recipe_id],
                data[:parsed_data][:recipe_ingredients_data]
              )
            end
          end

          results
        end
      end
    end
  end
end
