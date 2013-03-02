require 'sinatra'
require 'pry'
require 'json'
require 'haml'
require 'sinatra/cometio'
require 'active_record'

#set :port, 4444
set :public_folder, 'public'
set :static_cache_control, [:public, :no_cache]
set :server, ['thin'] # needed to avoid eventmachine error

log = File.open("time.log", "a")

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database =>  'data.sqlite3'
)

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
    :section => 'messages',
    :value => JSON.parse(request.body.read)
  "OK"
end

post '/hipchat-message-received' do
  p JSON.parse(request.body.read)
  "OK"
end
