#!/usr/bin/ruby
require 'parsedate'

notes_path = File.expand_path('../actions.txt', __FILE__)
last_timestamp = `tail -1 #{notes_path}`.split("\t")[0]
last_time = Time.local(*ParseDate.parsedate(last_timestamp))
seconds_elapsed = Time.new.to_i - last_time.to_i
script_path = File.expand_path('../nag-about-lack-of-notes.sh', __FILE__)
if seconds_elapsed > 60 * 60
  `touch #{lock_path}`
  `bash -c '#{script_path} #{last_time.strftime('%l:%M%p')}'`
end
