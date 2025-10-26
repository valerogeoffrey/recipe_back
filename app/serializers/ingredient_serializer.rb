# frozen_string_literal: true

# == Schema Information
#
# Table name: ingredients
#
#  id           :bigint           not null, primary key
#  default_name :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_ingredients_on_default_name  (default_name) UNIQUE
#

class IngredientSerializer < ActiveModel::Serializer
  attributes :id, :name, :quantities, :units

  def name
    object.default_name
  end

  def quantities
    object.distinct_quantities
  end

  def units
    object.distinct_units
  end
end
