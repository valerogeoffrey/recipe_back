# frozen_string_literal: true

module Api
  module V1
    class RecipesController < ApplicationController
      include Api::ParameterValidation

      before_action -> { validate_pagination!(pagination) }, only: [:index]
      before_action -> { validate_sort!(sort, whitelist: Recipe::VALID_SORT_OPTIONS) }, only: [:index]

      before_action -> { validate_recipe_filters! }, only: [:index]
      before_action -> { validate_recipe_id!(params[:id]) }, only: [:show]

      # GET /api/v1/recipes
      # /!\ all params with (**) are optional
      # Params:
      #   filter[title] (string**): Filter recipes by title (fuzzy search)
      #   filter[max_prep_time] (integer**): Maximum preparation time in minutes
      #   filter[max_cook_time] (integer**): Maximum cooking time in minutes
      #   filter[ingredient_ids] (array of integers**): Filter by ingredient IDs (simple mode)
      #   filter[ingredients] (array of hashes**): Filter by ingredients with quantity/unit
      #     - ingredient_id (integer, required): Ingredient ID
      #     - quantity (float, optional): Quantity value
      #     - unit (string, optional): Unit (e.g., 'milliliter', 'unit', 'gram')
      #   --
      #   pagination[page](integer**): Page number for pagination
      #   pagination[per_page] (integer**): Number of items per page
      #   --
      #   sort[by] (string**): Sort order (valid options defined in Recipe::VALID_SORT_OPTIONS)
      #
      # Examples:
      #   Simple: GET /api/v1/recipes?filter[ingredient_ids][]=5&filter[ingredient_ids][]=8
      #   Advanced: GET /api/v1/recipes?filter[ingredients][][ingredient_id]=5&filter[ingredients][][quantity]=300&filter[ingredients][][unit]=milliliter
      def index
        data = Recipes::Search.call(filters, pagination, sort)
        render json: data
      end

      # GET /api/v1/recipes/:id
      # Params:
      #   id (integer, required): Recipe ID
      def show
        recipe = Recipe.includes(:ingredients).find(params[:id])
        render json: recipe, serializer: DisplayRecipeSerializer
      end

      private

      def filters
        @filters ||= begin
          filter_params = params.fetch(:filter, {}).permit(
            :title,
            :max_prep_time,
            :max_cook_time,
            ingredient_ids: [],
            ingredients: %i[ingredient_id quantity unit]
          )

          Recipes::FilterSanitizer.new(filter_params.to_h).sanitize
        end
      end

      def validate_recipe_id!(id)
        return render_validation_errors(['Invalid recipe ID format']) unless id.to_s.match?(/^\d+$/)

        render_validation_errors(['Invalid recipe ID format']) unless id.to_i.positive?
      end

      def validate_recipe_filters!
        ok, errors = Recipes::FilterValidator.new(filters).validate!
        return if ok

        render_validation_errors(errors)
      end
    end
  end
end
