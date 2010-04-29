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

  begin
    req = REXML::Document.new(xml)
    r = ""
    req.write(r, 3)
    div = CodeRay.scan(r, :xml).div
  rescue
    div = CodeRay.scan(xml, :xml).div
  end

  begin
    n = Nokogiri.XML(xml)
    values = get_values([n.root.name], n.root, [])
  rescue
    values = []
  end

  { :headers => harr, :body => div, 
    :header_raw => header, :body_raw => xml,
    :http => http, :body_values => values
  }
end

def get_line(data)
  data.split("\n").first.gsub("HTTP/1.1", '')
rescue
  'fu'
end

def url_filter(url, id)
  group = @groups[id]
  base = @vars[group]['base']
  act = @vars[group]['act']
  ver = @vars[group]['ver']
  url = url.gsub(base, '<span class="base">[base]</span>')
  url = url.gsub(act, '<span class="act">[act]</span>')
  url = url.gsub(ver, '<span class="ver">[ver]</span>')
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

post '/create/:name' do
  name = params[:name]
  data = params[:sessions]
  @snifter = Snifter.new
  @snifter.save_group(name, data)
end

get '/groups' do
  @snifter = Snifter.new
  @groups = @snifter.groups
  erb :groups
end

get '/compare' do
  pp params
  @snifter = Snifter.new
  @compare = []
  @vars = {}
  @groups = [params[:sessA], params[:sessB]]
  @groups.each do |grp|
    sessions = @snifter.get_group(grp)
    group = []
    sessions.each do |sess|
      req, res, time = @snifter.session(sess)
      req = get_line(req)
      res = get_line(res)

      # check for variables for better comparison
      if m = /OPTIONS (.*)/.match(req)
        @vars[grp] ||= {}
        @vars[grp]['base'] = m[1].strip
      end
      if m = /MKACTIVITY (.*?)\/act\/(.*)/.match(req)
        @vars[grp] ||= {}
        @vars[grp]['act'] = m[2].strip
      end
      if m = /CHECKOUT (.*?)\/!svn\/bln\/(.*)/.match(req)
        @vars[grp] ||= {}
        @vars[grp]['ver'] = m[2].strip
      end
      group << [sess, req, res, time]
    end
    @compare << group
  end
  erb :compare
end

get '/clear_groups' do
  Snifter.new.clear_groups
  "cleared"
end

