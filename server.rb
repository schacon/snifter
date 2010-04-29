require 'rubygems'
require 'em-proxy'

require 'snifter'
require 'pp'

@snifter = Snifter.new

from_port = ARGV[0].to_i
to_port = ARGV[1].to_i

puts "Proxying from #{from_port} to #{to_port}"

listen_port = from_port
host_to = ['127.0.0.1', to_port]

@@sessions = {}

Proxy.start(:host => "0.0.0.0", :port => listen_port, :debug => false) do |conn|
  conn.server :srv, :host => host_to[0], :port => host_to[1]

  # modify / process request stream
  conn.on_data do |data|
    if id = @@sessions[conn.object_id]
      id = conn.object_id.to_s + rand(1000).to_s
      @@sessions[conn.object_id] = id
    else
      id = @@sessions[conn.object_id] = conn.object_id
    end
    @snifter.log_connect(id)
    @snifter.log_data(id, data)
    data
  end

  # modify / process response stream
  conn.on_response do |backend, resp|
    id = @@sessions[conn.object_id]
    @snifter.log_response(id, backend, resp)
    resp
  end

end
