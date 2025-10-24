# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Chaos::Postgresql
  include Api::ErrorHandling
  include RequestLocalizable
  include Paginable
  include Sortable
end
