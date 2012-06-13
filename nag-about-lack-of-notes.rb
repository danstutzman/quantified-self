#!/usr/bin/ruby
require 'parsedate'

DATA_PATH = File.expand_path('../data/actions.sqlite3', __FILE__)
latest_start_time = `echo 'select start_time from actions order by the_date desc, start_time desc limit 1;' | sqlite3 #{DATA_PATH}`.strip
latest_finish_time = `echo 'select finish_time from actions order by the_date desc, start_time desc limit 1;' | sqlite3 #{DATA_PATH}`.strip
latest_time = (latest_finish_time != '') ? 
  latest_finish_time : latest_start_time

script_path = File.expand_path('../nag-about-lack-of-notes.sh', __FILE__)
match = latest_time.match(/^([0-9][0-9]):([0-9][0-9]):([0-9][0-9])$/)
if match.nil?
  raise "Can't parse time #{latest_time}"
end
last_time = Time.local(
  Time.now.year, Time.now.month, Time.now.day,
  match[1], match[2], match[3]
)
seconds_elapsed = Time.new.to_i - last_time.to_i
if seconds_elapsed > 60 * 60 # if an hour has elapsed
  `bash -c '#{script_path} #{last_time.strftime('%l:%M%p')}'`
end
