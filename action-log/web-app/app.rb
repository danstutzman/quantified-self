require 'sinatra'
require 'haml'
require 'data_mapper'
require 'sinatra/flash'

set :port, 2999
enable :sessions

DataMapper::Logger.new(STDOUT, :debug)
db_path = File.expand_path('../../../data/actions.sqlite3', __FILE__)
DataMapper.setup :default, "sqlite3:#{db_path}"
class Action
  include DataMapper::Resource
  property :id, Serial, :required => true
  property :the_date, String, :required => true
  property :start_time, String, :required => true
  property :finish_time, String, :required => false
  property :category, String, :required => true
  property :notes, String, :required => false
end
DataMapper.auto_upgrade!
DataMapper::Model.raise_on_save_failure = true
DataMapper.finalize

def no_seconds(hms)
  return nil if hms.nil?
  return '' if hms == ''

  match = hms.match(/^([0-9]+):([0-9]+)(:([0-9]+))?/)
  if match.nil?
    raise "Bad value: #{hms.inspect}"
  end
  h, m, s = match[1].to_i, match[2].to_i, (match[4] || '').to_i
  sprintf('%02d:%02d', h, m)
end

def combine_times(hm, hms)
  if hm == ''
    nil
  elsif hms.index(hm) == 0
    hms
  else
    h, m = hm.split(':')
    sprintf('%02d:%02d:%02d', h.to_i, m.to_i, 0)
  end
end

def blank_to_nil(input)
  (input == '') ? nil : input
end

get '/' do
  today = Time.now.strftime('%Y-%m-%d')
  redirect "/#{today}"
end

get '/favicon.ico' do
  ''
end

get '/:date' do |date|
  raise "Bad date #{date}" if !date.match(/^[0-9-]+$/)
  @rows = Action.all(:the_date => date, :order => [:the_date, :start_time])
  @am_in_activity = @rows.size > 0 && @rows.last.finish_time.nil?
  if !@am_in_activity
    @rows.push Action.new(:id => (Action.max(:id) || 0) + 1)
  end
  haml :grid
end

post '/:date' do |date|
  raise "Bad date #{date}" if !date.match(/^[0-9-]+$/)

  if params['delete']
    Action.get(params['id']).destroy
  else
    action = Action.get(params['id']) || Action.new
    action.id = params['id']
    action.the_date = date
    action.start_time = combine_times(
      params['start_time'], params['start_time_seconds'])
    action.finish_time = combine_times(
      params['finish_time'], params['finish_time_seconds'])
    action.category = blank_to_nil(params['category'])
    action.notes = blank_to_nil(params['notes'])
    begin
      action.save!
    rescue DataMapper::SaveFailureError => e
      flash[:error] = e.to_s
    end
  end

  redirect "/#{date}"
end
