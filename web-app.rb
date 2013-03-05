require 'sinatra'
require 'pry'
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

log = File.open("time.log", "a")

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

get '/' do
  haml :page
end

post '/append-log' do
  unparsed_json = request.body.read
  hash = JSON.parse(unparsed_json)
  puts hash
  log.puts hash
  log.flush
  'OK'
end

get '/self-control' do
  if File.exists?('/etc/SelfControl.lock')
    puts "Lock file exists"
  else
    `sudo /Applications/SelfControl.app/Contents/MacOS/org.eyebeam.SelfControl 501 --install`
  end
end

get '/9' do
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

after do
  ActiveRecord::Base.clear_active_connections!
end
