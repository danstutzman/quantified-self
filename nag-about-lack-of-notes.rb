#!/usr/bin/ruby
require 'parsedate'

today = Time.now.strftime('%Y-%m-%d')
notes_path = File.expand_path("../../action_log/#{today}.tsv", __FILE__)
script_path = File.expand_path('../nag-about-lack-of-notes.sh', __FILE__)
if File.exists?(notes_path)
  last_line = `tail -1 #{notes_path}`.split("\t")
  last_timestamp = (last_line[2] != '') ? last_line[2] : last_line[1]
  match = last_timestamp.match(/^([0-9][0-9]):([0-9][0-9]):([0-9][0-9])$/)
  last_time = Time.local(
    Time.now.year, Time.now.month, Time.now.day,
    match[1], match[2], match[3])
  seconds_elapsed = Time.new.to_i - last_time.to_i
  if seconds_elapsed > 60 * 60 # if an hour has elapsed
    `bash -c '#{script_path} #{last_time.strftime('%l:%M%p')}'`
  end
else
  `bash -c '#{script_path} "you woke up"'`
end
