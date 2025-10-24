# frozen_string_literal: true

module Recipes
  module Normalize
    # Custom logger for migration operations
    # Creates a dedicated log file per migration run with timestamp
    class Logger
      attr_reader :logger, :log_file_path

      def initialize
        timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
        log_dir = Rails.root.join('log/normalizations')
        FileUtils.mkdir_p(log_dir)

        @log_file_path = log_dir.join("normalization_#{timestamp}.log")
        @logger = ::Logger.new(@log_file_path)
        @logger.level = ::Logger::DEBUG
        @logger.formatter = proc do |severity, datetime, _progname, msg|
          "[#{datetime.strftime('%Y-%m-%d %H:%M:%S.%3N')}] #{severity.ljust(5)} | #{msg}\n"
        end

        info '=' * 80
        info "Normalizations started at #{Time.current}"
        info "Log file: #{@log_file_path}"
        info '=' * 80
      end

      delegate :debug, to: :@logger

      def info(message)
        @logger.info(message)
        Rails.logger.debug message
      end

      def warn(message)
        @logger.warn(message)
        Rails.logger.debug "⚠️  #{message}".yellow if defined?(String.colors)
      end

      def error(message)
        @logger.error(message)
        Rails.logger.debug "❌ #{message}".red if defined?(String.colors)
      end

      def success(message)
        @logger.info("[SUCCESS] #{message}")
        Rails.logger.debug "✅ #{message}".green if defined?(String.colors)
      end

      def stats(stats_hash)
        info ''
        info '=' * 80
        info 'MIGRATION STATISTICS'
        info '=' * 80
        stats_hash.each do |key, value|
          info "  #{key.to_s.ljust(30)}: #{value}"
        end
        info '=' * 80
      end

      def close
        info ''
        info '=' * 80
        info "Migration completed at #{Time.current}"
        info "Log saved to: #{@log_file_path}"
        info '=' * 80
        @logger.close
      end
    end
  end
end
