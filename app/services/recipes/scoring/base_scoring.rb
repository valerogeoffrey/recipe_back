# frozen_string_literal: true

module Recipes
  module Scoring
    module BaseScoring
      BONUS_ALL_INGREDIENTS_MATCH = APP_CONF.dig(:scoring, :bonus_all_match) || 20
      BONUS_SMALL_RECIPE = APP_CONF.dig(:scoring, :bonus_small_recipe) || 10
      BONUS_MEDIUM_RECIPE = APP_CONF.dig(:scoring, :bonus_mid_recipe) || 5
      SMALL_RECIPE_THRESHOLD = APP_CONF.dig(:scoring, :small_recipe_treshold) || 5
      MEDIUM_RECIPE_THRESHOLD = APP_CONF.dig(:scoring, :mid_recipe_treshold) || 8
    end
  end
end
