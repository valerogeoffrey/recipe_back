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
FactoryBot.define do
  factory :ingredient do
    sequence(:default_name) { |n| "Ingredient #{n}" }
  end
end
