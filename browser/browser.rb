require 'rubygems'
require 'sinatra'
require 'coderay'

require 'rexml/document'
require 'nokogiri'
require 'cgi'
require 'pp'

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/..')
require 'snifter'

def get_values(context, node, values)
  node.children.each do |a|
    if a.element?
      new_context = context + [a.name]
      values = get_values(new_context, a, values)
    else
      data = a.content.strip
      if !data.empty?
        values << [context.join('.'), data]
      end
    end
  end
  if node.children.size == 0
    values << [context.join('.'), node.name]
  end
  values
end

def process_http(req)
  header, xml = req.split("\r\n\r\n")

  headers = header.split("\r\n")
  http = headers.shift
  harr = headers.map { |h| h.split(': ') }

  req = REXML::Document.new(xml)
  r = ""
  req.write(r, 3)
  div = CodeRay.scan(r, :xml).div

  n = Nokogiri.XML(xml)
  values = get_values([n.root.name], n.root, [])

  { :headers => harr, :body => div, 
    :header_raw => header, :body_raw => xml,
    :http => http, :body_values => values
  }
end

def get_line(data)
  data.split("\n").first.gsub("HTTP/1.1", '')
end

get '/' do
  @snifter = Snifter.new
  @sessions = []
  sessions = @snifter.current
  sessions.each do |sess|
    req, res, time = @snifter.session(sess)
    req = get_line(req)
    res = get_line(res)
    @sessions << [sess, req, res, time]
  end
  erb :index
end

get '/sess/:sess' do
  puts sess = params[:sess]
  @snifter = Snifter.new
  req, res = @snifter.session(sess)

  @req = process_http(req)
  @res = process_http(res)
  erb :session
end


