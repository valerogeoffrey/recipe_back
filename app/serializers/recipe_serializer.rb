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
class RecipeSerializer < ActiveModel::Serializer
  attributes :id, :title, :match_percentage, :relevance_score, :locale, :prep_time, :cook_time, :rating, :author, :image

  def locale
    I18n.locale.to_s
  end

  def title
    object.default_title
  end

  def total_time
    object.prep_time.to_i + object.cook_time.to_i
  end

  def match_percentage
    object.respond_to?(:match_percentage) ? object.match_percentage.to_f : false
  end

  def relevance_score
    object.respond_to?(:relevance_score) ? object.relevance_score.to_f : false
  end
end
