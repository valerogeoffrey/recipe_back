require "connection_pool"
require "redis"

REDIS_POOL = ConnectionPool.new(size: 5, timeout: 2) do
  Redis.new(
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    driver: :ruby
  )
end
