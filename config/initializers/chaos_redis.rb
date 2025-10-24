# config/initializers/chaos_redis.rb (dev only)
if Rails.env.development? && ENV['CHAOS_REDIS'] == '1'
  module ChaosRedis
    def self.maybe_boom!
      raise Redis::CannotConnectError if rand < (ENV.fetch('CHAOS_PROB', 0.1).to_f)
    end
  end

  Redis.class_eval do
    alias_method :__orig_get, :get
    def get(*args)
      ChaosRedis.maybe_boom!
      __orig_get(*args)
    end
  end
end
