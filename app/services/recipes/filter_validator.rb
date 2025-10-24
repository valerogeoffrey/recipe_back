# frozen_string_literal: true

module Recipes
  class FilterValidator
    CONF = {
      title_max_length: APP_CONF.dig(:validation, :recipes, :title_max_length) || 200,
      max_ingredient_ids: APP_CONF.dig(:validation, :recipes, :max_ingredient_ids) || 50
    }.freeze

    ERR_TITLE_TOO_LONG            = :title_is_too_long
    ERR_TITLE_INVALID_CHARS       = :title_contain_invalid_chars
    ERR_TOO_MANY_INGREDIENTS      = :too_many_ingredient_ids
    ERR_INVALID_INGREDIENTS       = :invalid_ingredient_ids
    ERR_INVALID_QUANTITY          = :invalid_quantity
    ERR_INVALID_UNIT              = :invalid_unit

    attr_reader :errors, :filter_params

    def initialize(filter_params)
      @filter_params = filter_params
      @errors = []
    end

    def validate!
      validate_title
      validate_ingredient_ids
      validate_ingredients_advanced
      return [false, @errors] if @errors.any?

      [true, @errors]
    end

    private

    def validate_title
      return if filter_params[:title].blank?

      title = filter_params[:title]
      errors << ERR_TITLE_TOO_LONG if title.length > CONF[:title_max_length]
      errors << ERR_TITLE_INVALID_CHARS if title.match?(/[<>"'&]/)
      #  TODO - chars could be extract and reuse in every validator
    end

    def validate_ingredient_ids
      return if filter_params[:ingredient_ids].blank?

      ingredient_ids = Array(filter_params[:ingredient_ids])
      errors << ERR_TOO_MANY_INGREDIENTS if ingredient_ids.length > CONF[:max_ingredient_ids]

      invalid_ids = ingredient_ids.reject { |id| id.to_s.match?(/^\d+$/) }
      errors << ERR_INVALID_INGREDIENTS if invalid_ids.any?
    end

    def validate_ingredients_advanced
      return if filter_params[:ingredients].blank?

      ingredients = Array(filter_params[:ingredients])
      errors << ERR_TOO_MANY_INGREDIENTS if ingredients.length > CONF[:max_ingredient_ids]

      ingredients.each do |ing|
        unless ing.is_a?(Hash) && ing[:ingredient_id].present?
          errors << ERR_INVALID_INGREDIENTS
          next
        end

        errors << ERR_INVALID_QUANTITY if ing[:quantity].present? && (ing[:quantity].to_f <= 0)

        errors << ERR_INVALID_UNIT if ing[:unit].present? && !valid_unit?(ing[:unit])
      end
    end

    def valid_unit?(unit)
      return false if unit.blank?
      return false if unit.length > 50

      #  Todo - Could use a whitelist of allowed units here ...

      true
    end
  end
end
