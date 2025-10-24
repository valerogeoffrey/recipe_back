# frozen_string_literal: true

module Recipes
  module Normalize
    # Processes individual recipes
    # Handles parsing, validation, and recipe creation
    class RecipeOrchestrator
      attr_reader :json_recipe, :ingredient_parser, :errors

      def initialize(json_recipe)
        @json_recipe = json_recipe
        @errors = []
      end

      delegate :logger, to: Recipes::Normalize

      # Main entry point for processing a single recipe within a batch
      # 1) Validates, 2) parses ingredients, 3) creates recipe, and 4) accumulates data
      # Ingredients are not persisted at this step
      def process(all_ingredient_names, recipes_with_ingredients)
        result = Recipe.valid_json_recipe?(json_recipe) ? Result.success(:ok) : Result.failed('Invalid recipe', status: Errors::INVALID_RECIPE)
        return result if result.failed?

        existing_recipe = Recipe.find_by(default_title: json_recipe['title'].to_s)
        if existing_recipe&.recipe_ingredients&.any?
          logger.debug "[SKIP] '#{existing_recipe.default_title}' (already exists with ingredients)"
          return Result.success(existing_recipe)
        end

        # CRITICAL: Parse ingredients BEFORE creating recipe to validate
        # need to be sure that we have always the same result for each ingredients
        # amount / unit / container_unit / ingredient
        parsed_data = parse_recipe_ingredients(json_recipe)

        if parsed_data[:ingredient_names].empty?
          logger.warn "[FAIL] No valid ingredients for '#{json_recipe['title']}'"
          logger.warn "  └─ Errors: #{@errors.join(', ')}" if @errors.any?
          return Result.failed("No valid ingredients extracted for '#{json_recipe['title']}'", status: Errors::INVALID_RECIPE)
        end

        result = create_or_update_recipe
        return result if result.failed?

        recipe = result.data
        all_ingredient_names.concat(parsed_data[:ingredient_names])

        recipes_with_ingredients << {
          recipe_id: recipe.id,
          parsed_data: parsed_data
        }

        Result.success(recipe)
      end

      private

      def create_or_update_recipe
        recipe = Recipe.find_or_create_by!(default_title: json_recipe['title'].to_s) do |r|
          r.cook_time = Recipe.sanitize_time(json_recipe['cook_time'])
          r.prep_time = Recipe.sanitize_time(json_recipe['prep_time'])
          r.rating = Recipe.sanitize_rating(json_recipe['ratings'])
          r.author = json_recipe['author']
          r.image = json_recipe['image']
        end

        Result.success(recipe)
      rescue ActiveRecord::RecordInvalid => e
        logger.error "[DB ERROR] Failed to create recipe '#{json_recipe['title']}': #{e.message}"
        Result.failed("Failed to create recipe: #{e.message}", status: Errors::DATABASE_ERROR)
      end

      # No DB insertion, only accumulation
      def parse_recipe_ingredients(json_recipe_data)
        parsed_ingredients = parse_ingredients(json_recipe_data['ingredients'])
        return empty_parsed_data if parsed_ingredients.empty?

        ingredient_names = extract_ingredient_names(parsed_ingredients)
        return empty_parsed_data if ingredient_names.empty?

        recipe_ingredients_data = build_recipe_ingredients(parsed_ingredients)

        {
          ingredient_names: ingredient_names,
          recipe_ingredients_data: recipe_ingredients_data
        }
      rescue StandardError => e
        logger.error "[EXCEPTION] Error parsing ingredients for '#{json_recipe_data['title']}'"
        logger.error "  └─ #{e.class}: #{e.message}"
        logger.error "  └─ Backtrace:\n#{e.backtrace.first(5).map { |l| "     #{l}" }.join("\n")}"
        empty_parsed_data
      end

      def parse_ingredients(ingredient_strings)
        parsed = []

        ingredient_strings.each_with_index do |ingredient_string, index|
          parsed_result = Ingredient.parse(ingredient_string)

          if parsed_result.failed?
            @errors << "Ingredient #{index + 1} (#{ingredient_string}): #{parsed_result.message}"
            next
          end

          parsed << {
            index: index,
            original: ingredient_string,
            parsed: parsed_result.data
          }
        end

        parsed
      end

      def extract_ingredient_names(parsed_ingredients)
        parsed_ingredients.map do |pi|
          name = Ingredient.extract_ingredient_name(pi[:parsed])
          next if name.blank?

          name.strip.singularize.downcase
        end.compact.uniq
      end

      def build_recipe_ingredients(parsed_ingredients)
        parsed_ingredients.map do |pi|
          ingredient_name = Ingredient.extract_ingredient_name(pi[:parsed])
          next if ingredient_name.blank?

          {
            original: pi[:original],
            parsed: pi[:parsed],
            ingredient_name: ingredient_name.strip.singularize
          }
        end.compact
      end

      def empty_parsed_data
        { ingredient_names: [], recipe_ingredients_data: [] }
      end
    end
  end
end
