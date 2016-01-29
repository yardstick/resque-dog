require 'bundler/setup'
Bundler.require

redis = Redis.new(
  host: ENV.fetch('REDIS_HOST'),
  port: ENV.fetch('REDIS_PORT').to_i,
  tcp_keepalive: 60
)
Resque.redis = Redis::Namespace.new('resque', redis: redis)

module Clockwork
  handler do |job|
    puts Resque.info.slice(:failed, :pending, :workers, :processed, :working)
  end

  every(5.seconds, 'resque')
end
