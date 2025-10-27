# frozen_string_literal: true

# == Schema Information
#
# Table name: recipe_ingredients
#
#  id               :bigint           not null, primary key
#  default_name     :string           not null
#  default_quantity :string
#  quantity_value   :decimal(8, 2)
#  unit             :string           default("unit"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  ingredient_id    :bigint           not null
#
# Indexes
#
#  index_recipe_ingredients_on_default_name_trgm   (default_name) USING gin
#  index_recipe_ingredients_on_ingredient_id       (ingredient_id)
#  index_recipe_ingredients_on_lower_default_name  (lower((default_name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (ingredient_id => ingredients.id)
#

class RecipeIngredientSerializer < ActiveModel::Serializer
  attributes :description, :ingredient, :raw_quantity, :quantity, :ingredient_id

  def ingredient
    object.ingredient.default_name
  end

  def ingredient_id
    object.ingredient.id
  end

  def raw_quantity
    object.default_quantity
  end

  def quantity
    object.quantity_value
  end

  def description
    object.default_name
  end
end
