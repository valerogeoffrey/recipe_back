# frozen_string_literal: true

module Chaos
  # Inspired by Netflix and Chaos Monkey
  # Prepare the system to be resiliente in case a tiers service is down ...
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
