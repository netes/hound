require 'resque/server'
require 'resque-retry'
require 'resque/failure/redis'

Resque::Server.use(Rack::Auth::Basic) do |user, password|
  password == ENV['RESQUE_ADMIN_PASSWORD']
end

Resque::Failure::MultipleWithRetrySuppression.classes = [
  Resque::Failure::Redis,
]
Resque::Failure.backend = Resque::Failure::MultipleWithRetrySuppression
Resque.redis.namespace = 'resque:hound'
