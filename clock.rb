require 'bundler/setup'
Bundler.require

redis = Redis.new(
  host: ENV.fetch('REDIS_HOST'),
  port: ENV.fetch('REDIS_PORT').to_i,
  tcp_keepalive: 60
)
Resque.redis = Redis::Namespace.new('resque', redis: redis)

module Clockwork
  Dog = Dogapi::Client.new(ENV.fetch('DD_API_KEY'), nil, ENV.fetch('DD_HOST'))

  handler do |job|
    Dog.batch_metrics do
      Resque.info.slice(:failed, :pending, :workers, :processed, :working).map do |k, v|
        Dog.emit_point("resque.#{k}", v)
      end
    end

    puts Resque.info.slice(:failed, :pending, :workers, :processed, :working)
  end

  every(15.seconds, 'resque')
end
