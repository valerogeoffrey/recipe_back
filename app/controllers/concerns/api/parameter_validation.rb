# frozen_string_literal: true

# Parameter validation concern for API controllers
# Provides consistent parameter validation across API endpoints
module Api
  module ParameterValidation
    extend ActiveSupport::Concern

    private

    def validate_pagination!(pagination_params)
      errors = []
      page = pagination_params[:page]
      errors << :page_must_be_positive unless page.positive?

      per_page = pagination_params[:per_page]
      errors << :per_page_must_be_positive unless per_page.positive?

      #  it should never happend - see paginable
      render_validation_errors(errors) if errors.any?
    end

    def validate_sort!(sort_params, whitelist:)
      return :valid if sort_params[:by].blank?
      return render_validation_errors([:missing_sort_options_for_the_resource]) unless whitelist
      return :valid if whitelist.include?(sort_params[:by])

      render_validation_errors([:invalid_sort_options])
    end
  end
end
