require 'rubygems'
require 'em-proxy'

require 'snifter'

@snifter = Snifter.new

Proxy.start(:host => "0.0.0.0", :port => 5201, :debug => false) do |conn|
  conn.server :srv, :host => "127.0.0.1", :port => 5200

  conn.on_connect do
    @snifter.log_connect(conn)
  end

  # modify / process request stream
  conn.on_data do |data|
    @snifter.log_data(conn, data)
    data
  end

  # modify / process response stream
  conn.on_response do |backend, resp|
    @snifter.log_response(conn, backend, resp)
    resp
  end

  # termination logic
  conn.on_finish do |backend, name|
    @snifter.log_finish(conn, backend, name)
  end
end
