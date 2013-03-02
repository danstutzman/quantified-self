require 'sinatra'
require 'pry'
require 'json'
require 'haml'
require 'sinatra/cometio'
require 'active_record'
require 'logger'

#set :port, 4444
set :public_folder, 'public'
set :static_cache_control, [:public, :no_cache]
set :server, ['thin'] # needed to avoid eventmachine error

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

post '/emails-updated' do
  CometIO.push :data,
    :section => 'email',
    :value => JSON.parse(request.body.read)
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
