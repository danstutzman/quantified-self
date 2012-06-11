#!/usr/bin/ruby

nanoseconds = `/usr/sbin/ioreg -c IOHIDSystem | sed -e '/HIDIdleTime/ !{ d' -e 't' -e '}' -e 's/.* = //g' -e 'q'`.to_i
seconds = nanoseconds / 1000000000
last_use = Time.now - seconds
hours = last_use.hour + (last_use.min / 60.0) + (last_use.sec / 3600.0)
hours += 24 if hours < 4.0
hours = sprintf("%.2f", hours)

yesterday = (Time.now - 8 * 60 * 60).strftime('%Y-%m-%d')
field = 'last-computer-use-hour'
path = File.expand_path('../data/last-computer-use.log', __FILE__)
value = hours
File.open(path, 'a') { |file|
  file.write "#{yesterday},#{field},#{value}\n"
}
