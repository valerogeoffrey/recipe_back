# frozen_string_literal: true

module RecipeIngredients
  module Units
    extend ActiveSupport::Concern

    # Can be useful for fallback - validation during parsing.
    UNITS = %w[
      cup cups teaspoon teaspoons tbsp tablespoon tablespoons
      ounce ounces oz gram grams g kg pound pounds lb lbs
      can cans package packages slice slices clove cloves
      pint pints quart quarts liter liters ml dl
      tablespoon(s) teaspoon(s)
    ].freeze

    FRACTIONS = '¼½¾⅓⅔⅕⅙⅛⅜⅝⅞'

     def self.units_regex
      /^(#{UNITS.join('|')})s?\s+/i
    end
  end
end
