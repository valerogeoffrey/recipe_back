# frozen_string_literal: true

class AddUnitOnRecipeIngredients < ActiveRecord::Migration[7.1]
  def change
    add_column :recipe_ingredients, :unit, :string, default: 'unit', null: false
  end
end
