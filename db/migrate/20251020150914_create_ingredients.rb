# frozen_string_literal: true

class CreateIngredients < ActiveRecord::Migration[7.1]
  def change
    create_table :ingredients do |t|
      t.string :default_name, null: false

      t.timestamps
    end

    # Constraint - force to unique recipe by default_name
    add_index :ingredients, :default_name, unique: true
  end
end
