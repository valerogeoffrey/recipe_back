# frozen_string_literal: true

module Ingredients
  class Search < BaseService
    include RequestCacheable

    attr_reader :filters, :pagination, :sort, :serializer

    def initialize(filters, pagination, sort, _options: {})
      @filters = filters
      @pagination = pagination
      @sort = sort
      @serializer = IngredientSerializer

      super()
    end

    def call
      cache_fetch(cache_key) do
        scope =
          Ingredient
          .select('ingredients.*, LENGTH(ingredients.default_name) AS name_length')
          .left_joins(:recipe_ingredients)
          .group('ingredients.id')
          .select(
            'ARRAY_AGG(DISTINCT recipe_ingredients.quantity_value) FILTER (WHERE recipe_ingredients.quantity_value IS NOT NULL) AS distinct_quantities',
            'ARRAY_AGG(DISTINCT recipe_ingredients.unit) FILTER (WHERE recipe_ingredients.unit IS NOT NULL) AS distinct_units'
          )
          .apply_filters(filters)
          .order_by(sort)

        ingredients = scope.page(page).per(per_page)
        serialize!(ingredients)
      end
    end

    private

    def cache_key
      cache_key_for(filters, pagination, sort)
    end

    def serialize!(recipes)
      ActiveModelSerializers::SerializableResource.new(
        recipes,
        each_serializer: serializer
      ).as_json
    end

    def page
      pagination[:page]
    end

    def per_page
      pagination[:per_page]
    end
  end
end
