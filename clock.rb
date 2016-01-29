require 'bundler/setup'

module Clockwork
  handle do |job|
    puts Dogapi::Client
  end
end
