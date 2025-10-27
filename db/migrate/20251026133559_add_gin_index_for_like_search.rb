# frozen_string_literal: true

class AddGinIndexForLikeSearch < ActiveRecord::Migration[7.1]
  def change
    add_index :recipes, :default_title,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: 'index_recipes_on_default_title_trgm'

    add_index :ingredients, :default_name,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: 'index_ingredients_on_default_name_trgm'

    add_index :recipe_ingredients, :default_name,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: 'index_recipe_ingredients_on_default_name_trgm'
  end
end
