# frozen_string_literal: true

module Recipes
  module Normalize
    module Errors
      SUCCESS = :success
      INVALID_RECIPE = :invalid_recipe
      INGREDIENT_PARSING_FAILED = :ingredient_parsing_failed
      DATABASE_ERROR = :database_error
      TRANSLATION_ERROR = :translation_error
      UNKNOWN_ERROR = :unknown_error
    end

    class << self
      attr_accessor :migration_logger

      def init_migration_logger
        @init_migration_logger ||= Recipes::Normalize::Logger.new
      end

      def logger
        @migration_logger || init_migration_logger
      end

      def reset_logger
        @migration_logger&.close
        @migration_logger = nil
      end

      # Process a single batch of recipes
      # Called by rake task which handles batching logic
      def call(batch)
        return [] if batch.empty?

        logger.debug "Processing batch of #{batch.size} recipes"
        BatchOrchestrator.process(batch)
      end
    end
  end
end
