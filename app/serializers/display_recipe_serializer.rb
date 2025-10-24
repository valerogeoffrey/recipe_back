# frozen_string_literal: true

# == Schema Information
#
# Table name: recipes
#
#  id         :bigint           not null, primary key
#  cook_time  :integer
#  prep_time  :integer
#  rating     :decimal(3, 2)
#  author     :string
#  image      :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# app/serializers/recipe_serializer.rb
class DisplayRecipeSerializer < RecipeSerializer
  has_many :recipe_ingredients
end
