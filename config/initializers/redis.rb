# config/initializers/redis.rb
require 'redis'

redis_url = ENV["REDIS_URL"] || "redis://localhost:6379"
$redis = Redis.new(url: redis_url)
