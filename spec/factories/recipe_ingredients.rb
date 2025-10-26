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
FactoryBot.define do
  factory :recipe_ingredient do
    association :ingredient
    quantity_value { 2 }
  end
end
