require 'sinatra'
require 'haml'

set :port, 2999

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
    ''
  elsif hms.index(hm) == 0
    hms
  else
    "#{hm}:00"
  end
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
  if File.exists?("#{date}.tsv")
    logs = File.read("#{date}.tsv")
  else
    logs = ""
  end
  @rows = logs.split("\n").collect { |row| row.split("\t") }
  @next_id = File.read("next_id").to_i
  raise "next_id shouldn't be 0" if @next_id == 0
  @am_in_activity = @rows.size > 0 && @rows.last[2] == ''
  if !@am_in_activity
    @rows.push [@next_id, '', '', '', '']
  end
  haml :grid
end

post '/:date' do |date|
  raise "Bad date #{date}" if !date.match(/^[0-9-]+$/)
  matched_id = false
  File.open("#{date}.tsv.new", 'w') { |outfile|
    if File.exists?("#{date}.tsv")
      File.open("#{date}.tsv") { |infile|
        infile.each_line { |line|
          id = line.split("\t")[0]
          if id == params['id']
            if matched_id
              raise "Should match id only once"
            else
              matched_id = true
            end
          else
            outfile.write line
          end
        }
      }
    end

    if !params['delete']
      start_time =
        combine_times(params['start_time'], params['start_time_seconds'])
      finish_time =
        combine_times(params['finish_time'], params['finish_time_seconds'])
      outfile.write [
        params['id'],
        start_time,
        finish_time,
        params['category'],
        params['notes'],
      ].join("\t") + "\n"
    end
  }
  File.rename "#{date}.tsv.new", "#{date}.tsv"

  old_next_id = File.read('next_id').to_i
  if params['id'].to_i + 1 >= old_next_id
    File.open('next_id', 'w') { |file|
      file.write("%s\n" % (params['id'].to_i + 1))
    }
  end

  redirect "/#{date}"
end
