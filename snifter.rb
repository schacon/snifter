require 'rubygems'
require 'redis'

class Snifter
  def initialize
    @redis = Redis.new
  end

  LIST_ID = 'snifter-conn-list'
  GROUP_ID = 'snifter-conn-group'

  def conn_id(conn)
    'snifter-conn-' + conn.to_s
  end

  def update_list(id)
    @redis.rpush LIST_ID, id
    @redis.ltrim LIST_ID, -30, -1
  end

  def log_connect(conn)
    add_data(conn, 'time', Time.now.to_i)
    update_list(conn_id(conn))
  end

  def add_data(conn, type, data)
    cid = conn_id(conn) + type
    if predata = @redis.get(cid)
      data = predata.to_s + data.to_s
    end
    @redis.set cid, data 
  end

  def log_data(conn, data)
    add_data(conn, 'request', data)
  end

  def log_response(conn, backend, resp)
    add_data(conn, 'response', resp)
  end

  def log_finish(conn, backend, name)
    p [:on_finish, conn]
  end

  def current
    @redis.lrange LIST_ID, 0, -1;
  end

  def groups
    @redis.lrange GROUP_ID, 0, -1;
  end

  def get_group(group)
    @redis.lrange group, 0, -1;
  end

  def clear_groups
    @redis.ltrim GROUP_ID, -1, -1
  end

  def save_group(name, data)
    time = rand(1000).to_s
    name = 'snifter_group_' + name + '_' + time

    @redis.rpush GROUP_ID, name

    data.each do |sess|
      puts "PUSH #{name} #{sess}"
      @redis.rpush name, sess
    end
  end

  def session(session)
    req = @redis.get session + 'request'
    res = @redis.get session + 'response'
    time = @redis.get session + 'time'
    [req, res, time.to_i]
  end

  def show_stats
    current.each do |conn|
      puts conn
      d = @redis.get conn + 'request'
      puts d.size rescue 'none'
      d = @redis.get conn + 'response'
      puts d.size rescue 'none'
      puts
    end
  end
end

