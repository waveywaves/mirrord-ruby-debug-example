#!/usr/bin/env ruby

require 'sinatra'
require 'redis'

# Get Redis URL from environment variable or default to localhost
redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379'
redis = Redis.new(url: redis_url)

get '/' do
  visits = redis.get('visits').to_i
  visits += 1
  redis.set('visits', visits)

  "<html>
    <head><title>Ruby + Redis</title></head>
    <body>
      <h1>Welcome to Ruby + Redis App!</h1>
      <p>Number of visits: #{visits}</p>
    </body>
  </html>"
end