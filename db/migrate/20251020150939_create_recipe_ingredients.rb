# frozen_string_literal: true

class CreateRecipeIngredients < ActiveRecord::Migration[7.1]
  def change
    create_table :recipe_ingredients do |t|
      t.references :ingredient, null: false, foreign_key: true
      t.string  :default_name, null: false
      t.string  :default_quantity
      t.decimal :quantity_value, precision: 8, scale: 2

      t.timestamps
    end
  end
end
