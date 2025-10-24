# frozen_string_literal: true

# app/controllers/concerns/localizable.rb
module RequestLocalizable
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
  end

  private

  def set_locale
    locale = params[:locale] ||
             request.headers['X-Locale'] ||
             I18n.default_locale

    I18n.locale = locale.to_sym if I18n.available_locales.include?(locale.to_sym)
  end

  def extract_locale_from_accept_language_header
    request.env['HTTP_ACCEPT_LANGUAGE']&.scan(/^[a-z]{2}/)&.first
  end
end
