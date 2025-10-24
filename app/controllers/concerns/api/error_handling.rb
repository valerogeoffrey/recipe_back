# frozen_string_literal: true

# Error handling concern for API controllers
# Provides consistent error responses and logging across API endpoints
module Api
  module ErrorHandling
    extend ActiveSupport::Concern

    included do
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    end

    private

    def handle_not_found(exception)
      render json: {
        error: 'not_found',
        message: 'The requested resource was not found',
        details: exception.message
      }, status: :not_found
    end

    # Render validation errors from custom validators
    # @param errors [Array<String>] List of error messages
    # @param status [Symbol] HTTP status (default: :bad_request)
    def render_validation_errors(errors, status: :bad_request)
      render_error(
        error: 'validation_failed',
        message: 'Invalid request parameters',
        details: errors,
        status: status
      )
    end

    # Generic error rendering method
    # @param error [String] Error type identifier
    # @param message [String] Human-readable error message
    # @param details [String, Array] Detailed error information
    # @param status [Symbol] HTTP status code
    def render_error(error:, message:, status:, details: nil)
      payload = {
        error: error,
        message: message
      }

      payload[:details] = details if details.present?

      render json: payload, status: status
    end
  end
end
