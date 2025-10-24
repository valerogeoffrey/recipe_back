# frozen_string_literal: true

# == Schema Information
#
# Table name: recipes
#
#  id            :bigint           not null, primary key
#  cook_time     :integer          default(0), not null
#  prep_time     :integer          default(0), not null
#  rating        :decimal(3, 2)    default(0.0), not null
#  default_title :string           not null
#  author        :string
#  image         :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
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
