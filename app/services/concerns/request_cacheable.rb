# app/services/concerns/cacheable.rb
# frozen_string_literal: true

module RequestCacheable
  extend ActiveSupport::Concern

  included do
    def cache_ttl
      (APP_CONF.dig(:cache, :ttl) || 30).seconds
    end
  end

  private

  def cache_fetch(key, ttl: cache_ttl)
    REDIS_POOL.with do |conn|
      cached = conn.get(key)
      return JSON.parse(cached) if cached

      result = yield
      conn.setex(key, ttl, result.to_json)
      result
    end
  rescue Redis::BaseError => e
    # Handle Chaos
    Rails.logger.error("[Cacheable] Redis unavailable: #{e.class} - #{e.message}")
    yield
  end

  def cache_key_for(*parts)
    digest = Digest::MD5.hexdigest(parts.map(&:to_s).join(':'))
    "#{self.class.name.underscore}:#{digest}"
  end
end
