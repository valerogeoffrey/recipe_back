# frozen_string_literal: true

module Chaos
  module Postgresql
    extend ActiveSupport::Concern

    included do
      rescue_from ActiveRecord::ConnectionNotEstablished,
                  ActiveRecord::StatementInvalid,
                  PG::ConnectionBad,
                  PG::UnableToSend do |error|
        Rails.logger.error("[DB] #{error.class}: #{error.message}")
        render json: { error: 'Database temporarily unavailable' }, status: :service_unavailable
      end
    end
  end
end
