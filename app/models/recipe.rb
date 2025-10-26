# frozen_string_literal: true

# == Schema Information
#
# Table name: recipes
#
#  id            :bigint           not null, primary key
#  author        :string
#  cook_time     :integer          default(0), not null
#  default_title :string           not null
#  image         :text
#  prep_time     :integer          default(0), not null
#  rating        :decimal(3, 2)    default(0.0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_recipes_on_cook_time      (cook_time)
#  index_recipes_on_default_title  (default_title) UNIQUE
#  index_recipes_on_prep_time      (prep_time)
#  index_recipes_on_rating         (rating)
#
class Recipe < ApplicationRecord
  include Recipes::Sortable
  include Recipes::Filterable

  has_many :recipe_recipe_ingredients, dependent: :destroy
  has_many :recipe_ingredients, through: :recipe_recipe_ingredients
  has_many :ingredients, through: :recipe_ingredients

  validates :cook_time, :prep_time, :default_title, :rating, presence: true
  validates :default_title, uniqueness: true
  validates :cook_time, :prep_time, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :rating, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 5.0 }

  # Validation and sanitization methods for JSON import
  def self.valid_json_recipe?(json_recipe)
    return false if json_recipe.nil?
    return false if json_recipe['title'].blank?
    return false if json_recipe['ingredients'].blank?
    return false unless json_recipe['ingredients'].is_a?(Array)

    true
  end

  def self.sanitize_time(value)
    return 0 if value.blank?

    value.to_i.clamp(0, 1440)
  end

  def self.sanitize_rating(value)
    return 0.0 if value.blank?

    value.to_f.clamp(0.0, 5.0)
  end

  #  Scoring attributes from scoring services ( basic / advanced )
  def matched_ingredients_count
    attributes['matched_ingredients'] || 0
  end

  def total_ingredients_count
    attributes['total_ingredients'] || recipe_ingredients.count
  end

  def match_percentage
    attributes['match_percentage'].to_f
  end

  def relevance_score
    attributes['relevance_score'].to_f
  end
end
