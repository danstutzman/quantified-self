require 'sinatra'

require 'json'
require 'haml'
require 'sinatra/cometio'
require 'active_record'
require 'logger'
require 'pp'

set :port, 4444
set :public_folder, 'public'
set :static_cache_control, [:public, :no_cache]
set :server, ['thin'] # needed to avoid eventmachine error
set :haml, { :format => :html5, :escape_html => true, :ugly => true }

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => 'data.sqlite3'
)

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.formatter = proc { |sev, time, prog, msg| "#{msg}\n" }

class HipchatMessage < ActiveRecord::Base
end

class FacebookMessage < ActiveRecord::Base
end

class UnansweredMessage < ActiveRecord::Base
  validates_presence_of :received_at
  validates_presence_of :sender
  validates_presence_of :medium
  validates_presence_of :email_uid, :if => lambda { |m| m.medium == 'email' }

  def age
    _then = self.received_at
    now = Time.now
    today = Time.new(now.year, now.month, now.day) - (7 * 24 * 60 * 60)
    that_day = Time.new(_then.year, _then.month, _then.day) - (7 * 24 * 60 * 60)
    ((today.to_f - that_day.to_f) / 86400.0).round.to_i
  end
end

class Task < ActiveRecord::Base
  validates_presence_of :name
end

class TaskBurndownUpdate < ActiveRecord::Base
  validates_presence_of :hours_left
end

class Log < ActiveRecord::Base
end

class AutoCompletion < ActiveRecord::Base
end

helpers do
  def task_burndown_chart
     # see https://developers.google.com/chart/image/docs/chart_params

     this_morning = Time.new(Time.now.year, Time.now.month, Time.now.day)
     tomorrow_morning = this_morning.advance(:days => 1)
     updates = TaskBurndownUpdate.where(
       'created_at > ? and created_at < ?', this_morning, tomorrow_morning
       ).order('created_at')
     updates.push TaskBurndownUpdate.new({
       :created_at => Time.now,
       :hours_left => updates.last ? updates.last.hours_left : 1,
     })

     xs = updates.map { |update|
       x = (update.created_at - this_morning) / 3600.0
       x = [8.0, x].max
       sprintf('%.1f', x)
     }
     xs.push xs.last

     ys = updates.map { |update| update.hours_left }
     ys.push ys.last

    '<img src="https://chart.googleapis.com/chart?cht=lxy&chs=400x250' +
    "&chd=t:#{xs.join(',')}|#{ys.join(',')}" +
    '&chco=3072F3,ff0000,00aaaa&chls=2,4,1&chm=s,ffffff,0,-1,5|s,000000,1,-1,5&chf=bg,s,00000000&chxt=x,y' +
    '&chds=8,24,0,12' +
    '&chxr=0,8,24,4|1,0,12,2' +
    '&chxs=0,aaaaaa,18|1,aaaaaa,18' +
    '">'
  end
end

get '/old' do
  haml :page
end

post '/append-log' do
  unparsed_json = request.body.read
  hash = JSON.parse(unparsed_json)
  puts hash

  log = Log.new
  log.start_date   = hash['startDate']
  log.finish_date  = hash['finishDate']
  log.message      = hash['message']
  log.activity_num = hash['activityNum']
  log.color        = hash['color']
  log.save!

  today_midnight = Time.new(Time.now.year, Time.now.month, Time.now.day
    ).strftime('%Y-%m-%d %H:%M:%S')
  sql = "select activity_num,
    sum(strftime('%s', finish_date) - strftime('%s', start_date))
    from logs
    group by activity_num;"
  activity_num_to_seconds = {}
  ActiveRecord::Base.connection.execute(sql, today_midnight).each do |row|
    activity_num, seconds = row[0], row[1]
    activity_num_to_seconds[activity_num] = seconds
  end
  JSON::dump(activity_num_to_seconds)
end

get '/self-control' do
  if File.exists?('/etc/SelfControl.lock')
    puts "Lock file exists"
  else
    `sudo /Applications/SelfControl.app/Contents/MacOS/org.eyebeam.SelfControl 501 --install`
  end
end

get '/' do
  haml :nine
end

get '/email-arrived' do
  CometIO.push :data, :name => 'temperature', :message => Time.now.to_s
  "OK"
end

post '/button-pressed' do
end

post '/unanswered_messages/update_emails' do
  hashes = JSON.parse(request.body.read)
  uids = [0]
  hashes.each do |hash|
    uid = hash["email_uid"]
    uids.push uid
    email = UnansweredMessage.find_by_email_uid(uid) ||
            UnansweredMessage.new({ :email_uid => uid })
    email.medium = "email"
    email.sender = hash["sender"]
    email.was_seen = hash["was_seen"]
    email.received_at = DateTime.strptime(hash["received_at"], '%Y-%m-%dT%H:%M:%S')
    email.save!
  end
  UnansweredMessage.where("medium = 'email' and email_uid not in (?)", uids).delete_all
  CometIO.push :update, :section => 'unanswered_messages'
  "OK"
end

post '/facebook-messages-updated' do
  hashes = JSON.parse(request.body.read)
  for hash in hashes
    from = hash["from"]
    timestamp = hash["timestamp"]

    new_message = FacebookMessage.new
    new_message.from_name = from
    new_message.save!
  end

  all_messages = FacebookMessage.all.map do |message|
    { "from" => message.from_name,
      "timestamp" => message.created_at }
  end

  CometIO.push :data, :section => 'facebook', :value => all_messages

  "OK"
end

post '/hipchat-message-received' do
  hash = JSON.parse(request.body.read)
  sender_nick = hash["sender_nick"]
  message = hash["message"]

  new_message = HipchatMessage.new
  new_message.sender_nick = sender_nick
  new_message.message = message
  new_message.save!

  all_messages = HipchatMessage.all.map do |message|
    { "created_at" => message.created_at,
      "sender_nick" => message.sender_nick,
      "message" => message.message }
  end

  CometIO.push :data, :section => 'hipchat', :value => all_messages

  "OK"
end

get '/unanswered_messages' do
  haml :_unanswered_messages
end

get '/tasks' do
  haml :_tasks
end

post '/tasks/edit_task' do
  if params['delete'] == 'true'
    task = Task.find(params['task_id'])
    task.destroy
  else
    if params['task_id'] == 'new'
      task = Task.new
    else
      task = Task.find(params['task_id'])
    end
    task.priority = params['priority']
    task.estimate = params['estimate']
    task.name     = params['name']
    task.save!
  end

  TaskBurndownUpdate.new({
    :created_at => Time.now,
    :hours_left => Task.all.map { |task| task.estimate }.sum
  }).save!

  CometIO.push :update, :section => 'tasks'

  redirect "/"
end

get '/refresh_all' do
  CometIO.push :update, :section => 'all'
end

after do
  ActiveRecord::Base.clear_active_connections!
end
