# frozen_string_literal: true

module Ingredients
  class FilterValidator
    CONF = {
      title_max_length: APP_CONF.dig(:validation, :ingredients, :title_max_length) || 100,
      max_ingredient_ids: APP_CONF.dig(:validation, :ingredients, :max_ingredient_ids) || 50
    }.freeze

    ERR_NAME_TOO_LONG         = :name_is_too_long
    ERR_NAME_INVALID_CHARS    = :name_contain_invalid_chars
    ERR_TOO_MANY_INGREDIENTS  = :too_many_ingredient_ids
    ERR_INVALID_INGREDIENTS   = :invalid_ingredient_ids

    attr_reader :errors, :filter_params

    def initialize(filter_params)
      @filter_params = filter_params
      @errors = []
    end

    def validate!
      validate_name_filter
      validate_ids_filter
      return [false, errors] if errors.any?

      [true, errors]
    end

    private

    def validate_name_filter
      return if filter_params[:name].blank?

      name = filter_params[:name]
      errors << ERR_NAME_TOO_LONG if name.length > CONF[:title_max_length]
      errors << ERR_NAME_INVALID_CHARS if name.match?(/[<>"'&]/)
      #  TODO - chars could be extract and reuse in every validator
    end

    def validate_ids_filter
      return if filter_params[:ids].blank?

      ids = Array(filter_params[:ids])
      validate_ids_count(ids)
      validate_ids_format(ids)
    end

    def validate_ids_count(ids)
      return unless ids.length > CONF[:max_ingredient_ids]

      errors << ERR_TOO_MANY_INGREDIENTS
    end

    def validate_ids_format(ids)
      invalid_ids = ids.reject { |id| id.to_s.match?(/^\d+$/) }
      return if invalid_ids.empty?

      errors << ERR_INVALID_INGREDIENTS
    end
  end
end
