require 'sinatra'
require 'pry'
require 'json'
require 'haml'

set :port, 4444
set :public_folder, 'public'
set :static_cache_control, [:public, :no_cache]

log = File.open("time.log", "a")

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

`open http://localhost:4444/`
