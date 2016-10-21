require 'bundler/setup'
Bundler.require

options = {
  url: ENV.fetch('REDIS_URL'),
  tcp_keepalive: 60
}
unless ENV.fetch('REDIS_SENTINEL').blank?
  options[:sentinels] = [{:host => ENV.fetch('REDIS_SENTINEL'), :port => 26379}]
end

redis = Redis.new(options)
Resque.redis = Redis::Namespace.new(ENV.fetch('REDIS_NAMESPACE'), redis: redis)

module Clockwork
  Dog = Dogapi::Client.new(ENV.fetch('DD_API_KEY'), nil, ENV.fetch('DD_HOST'))

  handler do |job|
    Dog.batch_metrics do
      Resque.info.slice(:failed, :pending, :workers, :processed, :working).each do |k, v|
        Dog.emit_point("resque.#{k}", v)
      end

      Resque.queues.each do |queue|
        Dog.emit_point("resque.queues.#{queue}.size", Resque.size(queue))
      end
    end
  end

  every(15.seconds, 'resque')
end
