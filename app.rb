#!/usr/bin/env ruby

require 'socket'

class RedisClient
  def initialize(host, port)
    @host = host
    @port = port
  end

  def connect
    @socket = TCPSocket.new(@host, @port)
  end

  def get(key)
    @socket.print "*2\r\n$3\r\nGET\r\n$#{key.length}\r\n#{key}\r\n"
    parse_response
  end

  def incr(key)
    @socket.print "*2\r\n$4\r\nINCR\r\n$#{key.length}\r\n#{key}\r\n"
    parse_response
  end

  private

  def parse_response
    line = @socket.gets
    case line[0]
    when ':'  # Integer
      line[1..-1].to_i
    when '$'  # Bulk String
      length = line[1..-1].to_i
      return nil if length == -1
      data = @socket.read(length)
      @socket.read(2)  # Read \r\n
      data
    else
      raise "Unknown response type: #{line}"
    end
  end
end

# Create Redis client
redis_host = ENV['REDIS_HOST'] || 'localhost'
redis_port = (ENV['REDIS_PORT'] || 6379).to_i
redis = RedisClient.new(redis_host, redis_port)
redis.connect

# HTTP Server
server = TCPServer.new('0.0.0.0', 4567)
puts "Server started at http://0.0.0.0:4567"

while session = server.accept
  request = session.gets
  puts request

  # Parse the request
  method, path = request.split(' ')

  if method == 'GET' && path == '/'
    visits = redis.incr('visits')
    
    # Create HTTP response
    content = "<html>
      <head><title>Ruby + Redis</title></head>
      <body>
        <h1>Welcome to Ruby + Redis App!</h1>
        <p>Number of visits: #{visits}</p>
      </body>
    </html>"

    session.print "HTTP/1.1 200 OK\r\n"
    session.print "Content-Type: text/html\r\n"
    session.print "Content-Length: #{content.length}\r\n"
    session.print "\r\n"
    session.print content
  else
    session.print "HTTP/1.1 404 Not Found\r\n\r\n"
  end

  session.close
end