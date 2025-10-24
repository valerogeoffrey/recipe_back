# frozen_string_literal: true

class AddUniqueIndexToRecipeIngredientsDefaultName < ActiveRecord::Migration[7.1]
  def change
    add_index :recipe_ingredients, 'LOWER(default_name)', unique: true, name: 'index_recipe_ingredients_on_lower_default_name'
  end
end
