# frozen_string_literal: true

module Recipes
  module Scoring
    class Basic < BaseService
      include BaseScoring

      attr_reader :scope, :ingredient_ids

      def initialize(scope, ingredient_ids)
        @scope = scope || Recipe.all
        @ingredient_ids = sanitize_ingredient_ids(ingredient_ids)

        super()
      end

      def call
        return scope if ingredient_ids.empty?

        # Wrap the scoring logic in a subquery
        # so that relevance_score becomes a real column usable for ordering/filtering
        scope.from("(#{recipes_with_relevance_scores.to_sql}) AS recipes").select('recipes.*')
      end

      private

      def sanitize_ingredient_ids(ids)
        Array(ids).map(&:to_i).compact.uniq.reject(&:zero?)
      end

      # Build the base query computing match ratios and relevance bonuses per recipe
      def recipes_with_relevance_scores
        Recipe
          .joins(<<~SQL.squish)
            LEFT JOIN recipe_recipe_ingredients AS rri
              ON rri.recipe_id = recipes.id
            LEFT JOIN recipe_ingredients AS matched_ri
              ON matched_ri.id = rri.recipe_ingredient_id
              AND matched_ri.ingredient_id IN (#{ingredient_ids.join(',')})
            LEFT JOIN recipe_ingredients AS all_ri
              ON all_ri.id = rri.recipe_ingredient_id
          SQL
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

      # Percentage of unique matched ingredients over the total ingredients in the recipe
      def match_percentage_sql
        <<~SQL.squish
          ROUND(
            (COUNT(DISTINCT matched_ri.ingredient_id)::float /
             NULLIF(COUNT(DISTINCT all_ri.ingredient_id), 0)::float * 100)::numeric,
            2
          )
        SQL
      end

      #   Full match bonus - all ingredients from the recipe have matched
      # + Small/medium recipe bonus - recipes with fewer ingredients are favored
      # > Relevance score = match percentage + bonuses
      # > Higher relevance for recipes that fully match all ingredients
      # > And for smaller recipes that are easier to cook with limited items
      def relevance_score_sql
        <<~SQL.squish
          (
            #{match_percentage_sql}
            + CASE
                WHEN COUNT(DISTINCT matched_ri.ingredient_id) = #{ingredient_ids.size}
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
