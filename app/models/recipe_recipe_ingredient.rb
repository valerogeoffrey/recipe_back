# frozen_string_literal: true

# == Schema Information
#
# Table name: recipe_recipe_ingredients
#
#  id                   :bigint           not null, primary key
#  recipe_id            :bigint           not null
#  recipe_ingredient_id :bigint           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class RecipeRecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :recipe_ingredient

  validates :recipe_id, uniqueness: { scope: :recipe_ingredient_id }
end
