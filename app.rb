#!/usr/bin/env ruby

require 'socket'
require 'time'
require 'cgi'

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

  def lpush(key, value)
    @socket.print "*3\r\n$5\r\nLPUSH\r\n$#{key.length}\r\n#{key}\r\n$#{value.length}\r\n#{value}\r\n"
    parse_response
  end

  def lrange(key, start, stop)
    @socket.print "*4\r\n$6\r\nLRANGE\r\n$#{key.length}\r\n#{key}\r\n$#{start.to_s.length}\r\n#{start}\r\n$#{stop.to_s.length}\r\n#{stop}\r\n"
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
    when '*'  # Array
      length = line[1..-1].to_i
      return [] if length == -1
      Array.new(length) { parse_response }
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

def parse_post_data(request)
  content_length = request.find { |line| line.start_with?('Content-Length:') }
  return {} unless content_length

  length = content_length.split(' ')[1].to_i
  body = request.last
  
  params = {}
  body.split('&').each do |param|
    key, value = param.split('=')
    params[key] = CGI.unescape(value.to_s)
  end
  params
end

# HTTP Server
server = TCPServer.new('0.0.0.0', 4567)
puts "Mirrord guestbook server started at http://0.0.0.0:4567"

while session = server.accept
  request_lines = []
  while line = session.gets
    request_lines << line.chomp
    break if line == "\r\n"
  end

  request = request_lines.first
  puts request

  method, path = request.split(' ')

  if method == 'GET' && path == '/'
    visits = redis.incr('visits')
    entries = redis.lrange('guestbook', 0, 9) || []
    
    content = <<-HTML
      <html>
        <head>
          <title>Mirrord + Ruby Guestbook</title>
          <style>
            body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
            .entry { border: 1px solid #ddd; margin: 10px 0; padding: 10px; border-radius: 5px; }
            .timestamp { color: #666; font-size: 0.8em; }
            form { margin: 20px 0; }
            textarea { width: 100%; height: 100px; margin: 10px 0; }
            button { padding: 10px 20px; background: #007bff; color: white; border: none; border-radius: 5px; }
          </style>
        </head>
        <body>
          <h1>Welcome to the Ruby Guestbook!</h1>
          <p>Total visits: #{visits}</p>
          
          <form method="POST" action="/">
            <div>
              <label for="name">Name:</label><br>
              <input type="text" id="name" name="name" required>
            </div>
            <div>
              <label for="message">Message:</label><br>
              <textarea id="message" name="message" required></textarea>
            </div>
            <button type="submit">Sign Guestbook</button>
          </form>

          <h2>Recent Entries</h2>
          #{entries.map { |entry|
            decoded = CGI.unescape(entry)
            name, message, timestamp = decoded.split('|')
            <<-ENTRY
              <div class="entry">
                <strong>#{CGI.escape_html(name)}</strong>
                <div>#{CGI.escape_html(message)}</div>
                <div class="timestamp">#{timestamp}</div>
              </div>
            ENTRY
          }.join("\n")}
        </body>
      </html>
    HTML

    session.print "HTTP/1.1 200 OK\r\n"
    session.print "Content-Type: text/html\r\n"
    session.print "Content-Length: #{content.length}\r\n"
    session.print "\r\n"
    session.print content

  elsif method == 'POST' && path == '/'
    content_length = request_lines.find { |line| line.start_with?('Content-Length:') }
    if content_length
      length = content_length.split(' ')[1].to_i
      body = session.read(length)
      
      params = {}
      body.split('&').each do |param|
        key, value = param.split('=')
        params[key] = CGI.unescape(value.to_s)
      end

      if params['name'] && params['message']
        entry = "#{params['name']}|#{params['message']}|#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
        redis.lpush('guestbook', CGI.escape(entry))
      end
    end

    session.print "HTTP/1.1 303 See Other\r\n"
    session.print "Location: /\r\n"
    session.print "\r\n"
  else
    session.print "HTTP/1.1 404 Not Found\r\n\r\n"
  end

  session.close
end