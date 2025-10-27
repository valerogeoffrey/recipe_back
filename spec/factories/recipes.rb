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
#  index_recipes_on_cook_time           (cook_time)
#  index_recipes_on_default_title       (default_title) UNIQUE
#  index_recipes_on_default_title_trgm  (default_title) USING gin
#  index_recipes_on_prep_time           (prep_time)
#  index_recipes_on_rating              (rating)
#
FactoryBot.define do
  factory :recipe do
    sequence(:default_title) { |n| "Recipe #{n}" }
    cook_time { 30 }
    prep_time { 15 }
    rating { 4.5 }
    author { 'Chef Test' }
  end
end
