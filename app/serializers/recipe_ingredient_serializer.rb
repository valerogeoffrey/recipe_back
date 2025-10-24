# frozen_string_literal: true

# == Schema Information
#
# Table name: recipe_ingredients
#
#  id               :bigint           not null, primary key
#  ingredient_id    :bigint           not null
#  default_name     :string           not null
#  default_quantity :string
#  quantity_value   :decimal(8, 2)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  unit             :string           default("unit"), not null
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
