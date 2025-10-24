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
class Ingredient < ApplicationRecord
  include Cacheable
  include BulkInsertable
  include Ingredients::Parsable

  VALID_SORT_OPTIONS = %w[title_asc].freeze

  has_many :recipe_ingredients, dependent: :destroy
  has_many :recipes, through: :recipe_ingredients

  validates :default_name, presence: true, uniqueness: { case_sensitive: false }

  scope :order_by, lambda { |sort_param, _locale = I18n.locale.to_s|
    return order(default_sort) if sort_param.blank?

    case sort_param[:by].to_s
    when 'title_asc' then order('ingredients.default_name ASC')
    else
      all
    end
  }

  scope :search_by_name, lambda { |query|
    return all if query.blank?

    where('ingredients.default_name ILIKE ?', "%#{sanitize_sql_like(query)}%")
  }

  scope :search_by_ids, lambda { |ids|
    return all if ids.blank?

    where(id: ids)
  }

  def self.apply_filters(params)
    recipes = all
    recipes = recipes.search_by_name(params[:name]) if params[:name].present?
    recipes = recipes.search_by_ids(params[:ids]) if params[:ids].present?
    recipes
  end

  def self.default_sort
    Arel.sql('LENGTH(ingredients.default_name) ASC')
  end

  def distinct_quantities
    return [] unless respond_to?(:distinct_quantities_value)

    distinct_quantities_value&.compact || []
  end

  def distinct_units
    return [] unless respond_to?(:distinct_units_value)

    distinct_units_value&.compact || []
  end

  def distinct_quantities_value
    attributes['distinct_quantities']
  end

  def distinct_units_value
    attributes['distinct_units']
  end
end
