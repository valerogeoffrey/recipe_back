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
class RecipeIngredient < ApplicationRecord
  include BulkInsertable
  include RecipeIngredients::Units

  belongs_to :ingredient
  has_many :recipe_recipe_ingredients, dependent: :destroy
  has_many :recipes, through: :recipe_recipe_ingredients

  validates :default_name, presence: true, uniqueness: { case_sensitive: false }

  def self.recipe_ingredient_exists?(name)
    RecipeIngredient.exists?(default_name: name)
  end
end
