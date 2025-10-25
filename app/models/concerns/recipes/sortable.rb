# frozen_string_literal: true

module Recipes
  module Sortable
    extend ActiveSupport::Concern

    included do
      VALID_SORT_OPTIONS = %w[
        title title_desc
        rating rating_desc
        prep_time prep_time_desc
        cook_time cook_time_desc
        relevance relevance_desc
      ].freeze

      scope :order_by, lambda { |sort_param, _locale = I18n.locale.to_s|
        return all if sort_param.blank?

        case sort_param[:by].to_s
        when 'title' then order('recipes.default_title ASC')
        when 'title_desc' then order('recipes.default_title DESC')
        when 'rating' then order(rating: :asc)
        when 'rating_desc' then order(rating: :desc)
        when 'prep_time' then order(prep_time: :asc)
        when 'prep_time_desc' then order(prep_time: :desc)
        else all
        end
      }

      # We assume that the relevance sorting is only applied after applying the scoring scopes
      scope :order_by_relevance, lambda { |sort_param|
        return all if sort_param.blank?

        case sort_param[:by].to_s
        when 'relevance_desc'
          order(Arel.sql('relevance_score DESC, match_percentage DESC, total_ingredients ASC, matched_ingredients DESC'))
        when 'relevance'
          order(Arel.sql('relevance_score ASC, match_percentage ASC, total_ingredients ASC, matched_ingredients ASC'))
        else
          all
        end
      }
    end
  end
end
