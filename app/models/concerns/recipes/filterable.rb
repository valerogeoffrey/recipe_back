# frozen_string_literal: true

module Recipes
  module Filterable
    extend ActiveSupport::Concern

    included do
      def self.filter_by(params)
        recipes = all
        recipes = recipes.search_by_title(params[:title]) if params[:title].present?
        recipes = recipes.filter_by_ingredients(recipes, params[:ingredient_ids]) if params[:ingredient_ids].present?
        recipes = recipes.filter_by_ingredients_advanced(recipes, params[:ingredients]) if params[:ingredients].present?
        recipes
      end

      scope :search_by_title, lambda { |query, _locale = I18n.locale.to_s|
        return all if query.blank?

        recipe_ids = where('recipes.default_title ILIKE ?', "%#{sanitize_sql_like(query)}%")
                     .select('recipes.id')
                     .distinct

        where(id: recipe_ids)
      }

      scope :filter_by_ingredients, lambda { |scope, ingredient_ids|
        return scope if ingredient_ids.blank?

        Recipes::Scoring::Basic.call(scope, ingredient_ids)
      }

      scope :filter_by_ingredients_advanced, lambda { |scope, ingredient_filters|
        return scope if ingredient_filters.blank?

        Recipes::Scoring::Advanced.call(scope, ingredient_filters)
      }
    end
  end
end
