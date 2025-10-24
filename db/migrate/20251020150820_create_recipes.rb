# frozen_string_literal: true

class CreateRecipes < ActiveRecord::Migration[7.1]
  def change
    create_table :recipes do |t|
      t.integer :cook_time, null: false, default: 0
      t.integer :prep_time, null: false, default: 0
      t.decimal :rating, precision: 3, scale: 2, null: false, default: 0.0
      t.string  :default_title, null: false
      t.string  :author
      t.text    :image

      t.timestamps
    end

    # Constraint - force to unique recipe by default_title
    add_index :recipes, :default_title, unique: true

    # Usefull for rating filters
    add_index :recipes, :rating,
              name: 'index_recipes_on_rating',
              if_not_exists: true

    # Usefull for prep_time filters
    add_index :recipes, :prep_time,
              name: 'index_recipes_on_prep_time',
              if_not_exists: true

    # Usefull for cook_time filters
    add_index :recipes, :cook_time,
              name: 'index_recipes_on_cook_time',
              if_not_exists: true
  end
end
