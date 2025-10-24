# frozen_string_literal: true

module Recipes
  class FilterSanitizer
    attr_reader :raw_filters

    def initialize(raw_filters)
      @raw_filters = raw_filters
    end

    def sanitize
      cleaned = raw_filters.dup

      cleaned[:title] = sanitize_title(cleaned[:title])
      cleaned[:ingredient_ids] = sanitize_ingredient_ids(cleaned[:ingredient_ids])
      cleaned[:ingredients] = sanitize_ingredients(cleaned[:ingredients]) if cleaned[:ingredients].present?

      cleaned.compact
    end

    private

    def sanitize_title(title)
      title&.strip&.presence
    end

    def sanitize_ingredient_ids(ingredient_ids)
      Array(ingredient_ids).map(&:to_i).uniq.compact.reject(&:zero?)
    end

    # Sanitize ingredient filters from params or any external input
    # Returns an array of hashes with symbolized keys:
    #   - :ingredient_id (integer, > 0)
    #   - :quantity (float, optional)
    #   - :unit (string, optional)
    def sanitize_ingredients(ingredients)
      Array(ingredients).map do |ing|
        next if ing[:ingredient_id].blank?

        {
          ingredient_id: ing[:ingredient_id].to_i,
          quantity: ing[:quantity]&.to_f,
          unit: ing[:unit]&.to_s&.strip&.presence
        }
      end.compact.reject { |f| f[:ingredient_id].zero? }
    end
  end
end
