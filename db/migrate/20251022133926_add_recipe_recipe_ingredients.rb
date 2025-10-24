# frozen_string_literal: true

class AddRecipeRecipeIngredients < ActiveRecord::Migration[7.1]
  def change
    create_table :recipe_recipe_ingredients do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :recipe_ingredient, null: false, foreign_key: true
      t.timestamps
    end

    add_index :recipe_recipe_ingredients, %i[recipe_id recipe_ingredient_id], unique: true, name: 'index_rri_on_recipe_and_ingredient'
    add_index :recipe_recipe_ingredients, %i[recipe_ingredient_id recipe_id], name: 'index_rri_on_ingredient_and_recipe'
  end
end
