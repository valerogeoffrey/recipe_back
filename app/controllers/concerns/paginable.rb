# frozen_string_literal: true

# app/controllers/concerns/localizable.rb
module Paginable
  extend ActiveSupport::Concern

  def pagination
    @pagination ||= begin
      pagination_params = params.fetch(:pagination, {}).permit(:page, :per_page)
      page     = pagination_params[:page]&.to_i || default_page
      per_page = pagination_params[:per_page]&.to_i || default_per_page

      {
        page: page.clamp(1, Float::INFINITY),
        per_page: per_page.clamp(1, max_per_page)
      }
    end
  end

  private

  def default_page = APP_CONF[:api][:pagination].[](:default_page)
  def default_per_page = APP_CONF[:api][:pagination].[](:default_per_page)
  def max_per_page = APP_CONF[:api][:pagination].[](:max_per_page)
end
