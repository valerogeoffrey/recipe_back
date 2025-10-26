# frozen_string_literal: true

# == Schema Information
#
# Table name: recipe_recipe_ingredients
#
#  id                   :bigint           not null, primary key
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  recipe_id            :bigint           not null
#  recipe_ingredient_id :bigint           not null
#
# Indexes
#
#  index_recipe_recipe_ingredients_on_recipe_id             (recipe_id)
#  index_recipe_recipe_ingredients_on_recipe_ingredient_id  (recipe_ingredient_id)
#  index_rri_on_ingredient_and_recipe                       (recipe_ingredient_id,recipe_id)
#  index_rri_on_recipe_and_ingredient                       (recipe_id,recipe_ingredient_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (recipe_id => recipes.id)
#  fk_rails_...  (recipe_ingredient_id => recipe_ingredients.id)
#
class RecipeRecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :recipe_ingredient

  validates :recipe_id, uniqueness: { scope: :recipe_ingredient_id }
end
