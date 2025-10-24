# frozen_string_literal: true

module Api
  module V1
    class IngredientsController < ApplicationController
      include Api::ParameterValidation

      before_action -> { validate_pagination!(pagination) }, only: [:index]
      before_action -> { validate_sort!(sort, whitelist: Ingredient::VALID_SORT_OPTIONS) }, only: [:index]

      before_action -> { validate_ingredient_filters! }, only: [:index]

      # GET /api/v1/ingredients
      # /!\ all params with (**) are optionnal
      # Params:
      #   filter[name] (string**): Filter ingredients by name (fuzzy search)
      #   filter[ids] (array of integers**): Filter by specific ingredient IDs
      #   pagination[page] (integer**): Page number for pagination
      #   pagination[per_page] (integer**): Number of items per page
      #   sort[by] (string**): Sort order (valid options defined in Ingredient::VALID_SORT_OPTIONS)
      def index
        ingredients = Ingredients::Search.call(
          filters, pagination, sort
        )

        render json: ingredients
      end

      private

      def filters
        @filters ||= begin
          filter_params = params.fetch(:filter, {}).permit(:name, ids: [])

          # sanitizing steps
          cleaned_filters = filter_params.to_h
          cleaned_filters[:name] = cleaned_filters[:name]&.strip&.presence
          cleaned_filters[:ids] = Array(cleaned_filters[:ids]).map(&:to_i).uniq.compact

          cleaned_filters.compact
        end
      end

      def validate_ingredient_filters!
        ok, errors = Ingredients::FilterValidator.new(filters).validate!
        return if ok

        render_validation_errors(errors)
      end
    end
  end
end
