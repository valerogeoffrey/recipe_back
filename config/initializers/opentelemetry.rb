# frozen_string_literal: true

if Rails.env.in?(%w[development]) && ENV['ENABLE_OPEN_TELEMETRY'] == 'true'
  require 'opentelemetry/sdk'
  require 'opentelemetry/exporter/otlp'
  require 'opentelemetry/instrumentation/all'

  OpenTelemetry::SDK.configure do |config|
    config.use_all # enables all instrumentation
    config.service_name = 'pennylane-backend'
    config.add_span_processor(
      OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
        OpenTelemetry::Exporter::OTLP::Exporter.new(
          endpoint: ENV.fetch('OTEL_EXPORTER_OTLP_ENDPOINT', 'http://172.17.0.1:4318/v1/traces')
        )
      )
    )
  end
end
