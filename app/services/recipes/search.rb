# frozen_string_literal: true

module Recipes
  class Search < BaseService
    include RequestCacheable

    attr_reader :filters, :pagination, :sort, :serializer

    def initialize(filters, pagination, sort, _options: {})
      @filters = filters
      @pagination = pagination
      @sort = sort
      @serializer = RecipeSerializer

      super()
    end

    def call
      cache_fetch(cache_key) do
        recipes = Recipe.filter_by(filters)
        recipes = apply_sorting!(recipes)
        serialize!(recipes.distinct.page(page).per(per_page))
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

    def apply_sorting!(recipes)
      recipes = recipes.order_by(sort)

      # Apply relevance sorting if filtering by ingredients (both modes)
      recipes = recipes.order_by_relevance(sort) if filters[:ingredient_ids].present? || filters[:ingredients].present?

      recipes
    end

    def page
      pagination[:page]
    end

    def per_page
      pagination[:per_page]
    end
  end
end
