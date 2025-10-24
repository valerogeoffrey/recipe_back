# frozen_string_literal: true

# app/controllers/concerns/localizable.rb
module Sortable
  extend ActiveSupport::Concern

  def sort
    params.fetch(:sort, {}).permit(:by)
  end
end
