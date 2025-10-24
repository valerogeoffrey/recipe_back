# frozen_string_literal: true

module Recipes
  module Scoring
    # Service that calculates an advanced relevance score for recipes
    # based on ingredient filters including quantity and unit
    class Advanced < BaseService
      include BaseScoring

      attr_reader :scope, :ingredient_filters

      def initialize(scope, ingredient_filters)
        @scope = scope || Recipe.all
        @ingredient_filters = ingredient_filters || []

        super()
      end

      def call
        return scope if ingredient_filters.empty?

        # Wrap the scoring logic in a subquery
        # so that relevance_score becomes a real column usable for ordering/filtering
        scope.from("(#{recipes_with_relevance_scores.to_sql}) AS recipes").select('recipes.*')
      end

      private

      # Build the query computing match ratios and relevance bonuses per recipe
      # matched_ri are ingredients that satisfy the filters (ingredient, quantity, unit)
      # all_ri are all ingredients in the recipe (used to compute match percentage)
      def recipes_with_relevance_scores
        Recipe
          .joins(join_clause)
          .group('recipes.id')
          .select(<<~SQL.squish)
            recipes.*,
            COUNT(DISTINCT matched_ri.ingredient_id) AS matched_ingredients,
            COUNT(DISTINCT all_ri.ingredient_id) AS total_ingredients,
            #{match_percentage_sql} AS match_percentage,
            #{relevance_score_sql} AS relevance_score
          SQL
          .having('COUNT(DISTINCT matched_ri.ingredient_id) > 0')
      end

      # Defines the necessary JOINs
      # - rri links recipes to ingredients
      # - matched_ri filters ingredients according to the user filters
      # - all_ri includes all ingredients of the recipe (for % match calculation)
      def join_clause
        <<~SQL.squish
          LEFT JOIN recipe_recipe_ingredients AS rri
            ON rri.recipe_id = recipes.id
          LEFT JOIN recipe_ingredients AS matched_ri
            ON matched_ri.id = rri.recipe_ingredient_id
            AND (#{match_conditions})
          LEFT JOIN recipe_ingredients AS all_ri
            ON all_ri.id = rri.recipe_ingredient_id
        SQL
      end

      # Build the SQL condition for ingredient filters
      # Example: (ingredient_id = 1 AND quantity <= 100 AND unit = 'g') OR (...)
      def match_conditions
        conditions = ingredient_filters.map do |filter|
          condition_parts = ["matched_ri.ingredient_id = #{filter[:ingredient_id]}"]
          condition_parts << "matched_ri.quantity_value <= #{filter[:quantity]}" if filter[:quantity].present?
          condition_parts << "matched_ri.unit = #{safe!(filter[:unit])}" if filter[:unit].present?

          "(#{condition_parts.join(' AND ')})"
        end

        conditions.join(' OR ')
      end

      # Prevent SQL injection
      def safe!(value)
        ActiveRecord::Base.connection.quote(value)
      end

      def match_percentage_sql
        <<~SQL.squish
          ROUND(
            (COUNT(DISTINCT matched_ri.ingredient_id)::float /
             NULLIF(COUNT(DISTINCT all_ri.ingredient_id), 0)::float * 100)::numeric,
            2
          )
        SQL
      end

      def relevance_score_sql
        <<~SQL.squish
          (
            #{match_percentage_sql}
            + CASE
                WHEN COUNT(DISTINCT matched_ri.ingredient_id) = #{ingredient_filters.size}
                THEN #{BONUS_ALL_INGREDIENTS_MATCH}
                ELSE 0
              END
            + CASE
                WHEN COUNT(DISTINCT all_ri.ingredient_id) <= #{SMALL_RECIPE_THRESHOLD}
                THEN #{BONUS_SMALL_RECIPE}
                WHEN COUNT(DISTINCT all_ri.ingredient_id) <= #{MEDIUM_RECIPE_THRESHOLD}
                THEN #{BONUS_MEDIUM_RECIPE}
                ELSE 0
              END
          )
        SQL
      end
    end
  end
end
