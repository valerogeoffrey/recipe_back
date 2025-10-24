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
class RecipeIngredient < ApplicationRecord
  include Cacheable
  include BulkInsertable
  include RecipeIngredients::Units

  belongs_to :ingredient
  has_many :recipe_recipe_ingredients, dependent: :destroy
  has_many :recipes, through: :recipe_recipe_ingredients

  validates :default_name, presence: true, uniqueness: { case_sensitive: false }
end
