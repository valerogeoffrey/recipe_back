# frozen_string_literal: true

module Recipes
  module Filterable
    extend ActiveSupport::Concern

    included do
      def self.filter_by(params)
        recipes = all
        recipes = recipes.search_by_title(params[:title]) if params[:title].present?
        recipes = recipes.with_ingredient_scoring(recipes, params[:ingredient_ids]) if params[:ingredient_ids].present?
        recipes = recipes.with_ingredient_advanced_scoring(recipes, params[:ingredients]) if params[:ingredients].present?
        recipes
      end

      scope :search_by_title, lambda { |query, _locale = I18n.locale.to_s|
        return all if query.blank?

        recipe_ids = where('recipes.default_title ILIKE ?', "%#{sanitize_sql_like(query)}%")
                     .select('recipes.id')
                     .distinct

        where(id: recipe_ids)
      }

      scope :with_ingredients, lambda { |ingredient_ids|
        return all if ingredient_ids.blank?

        ingredient_ids = Array(ingredient_ids).map(&:to_i).compact
        return all if ingredient_ids.empty?

        recipe_ids = joins(:recipe_ingredients)
                     .where(recipe_ingredients: { ingredient_id: ingredient_ids })
                     .group('recipes.id')
                     .having('COUNT(DISTINCT recipe_ingredients.ingredient_id) = ?', ingredient_ids.size)
                     .pluck(:id)

        where(id: recipe_ids)
      }

      scope :with_ingredient_scoring, lambda { |scope, ingredient_ids|
        return scope if ingredient_ids.blank?

        Recipes::Scoring::Basic.call(scope, ingredient_ids)
      }

      scope :with_ingredient_advanced_scoring, lambda { |scope, ingredient_filters|
        return scope if ingredient_filters.blank?

        Recipes::Scoring::Advanced.call(scope, ingredient_filters)
      }

      scope :with_ingredients_advanced, lambda { |ingredient_filters|
        return all if ingredient_filters.blank?

        scope = all

        ingredient_filters.each do |filter|
          next if filter[:ingredient_id].blank?

          scope = scope.joins(:recipe_ingredients)
                       .where(recipe_ingredients: { ingredient_id: filter[:ingredient_id] })

          scope = scope.where(recipe_ingredients: { quantity_value: ..(filter[:quantity]) }) if filter[:quantity].present?
          scope = scope.where(recipe_ingredients: { unit: filter[:unit] }) if filter[:unit].present?
        end

        scope.distinct
      }
    end
  end
end
