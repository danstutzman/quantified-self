#!/usr/bin/ruby
require 'parsedate'

# don't require sqlite3 gem; it could be a pain for the user to compile
SQLITE='/usr/bin/sqlite3'

if ARGV[0].nil?
  STDERR.write "Usage: first arg should be date, for example: 2012-05-28\n"
  exit 1
end
y, m, d = ParseDate.parsedate(ARGV[0])
if y && m && d
  DAY = Time.local(y, m, d)
else
  STDERR.write "Usage: first arg should be date, for example: 2012-05-28\n"
  exit 1
end

lines = []
File.open(File.expand_path('../actions.txt', __FILE__)) { |file|
  file.each_line { |line|
    date_time = Time.local(*ParseDate.parsedate(line.split("\t")[0]))
    comment = line.split("\t")[1].strip
    if date_time.strftime('%Y-%m-%d') == DAY.strftime('%Y-%m-%d')
      lines.push [date_time.strftime('%H:%M:%S'), comment]
    end
  }
}

new_lines = []
lines.each { |line|
  time, comment = line
  comment.split(', ').each { |split_comment|
    new_lines.push [time, split_comment]
  }
}
lines = new_lines

logs = []
just_was_on_break = false
lines.each { |line|
  time, comment = line
  in_pm = time.match(/^(1[0-9]|2[0-3])/)

  if comment == 'no'
    if logs.last[2].nil?
      logs.pop # remove last log
    end
    next
  elsif comment.match(/^actually (.*)$/)
    if logs.last[2].nil?
      logs.pop # remove last log
    end
    comment = $1
  elsif comment.match(/([0-9]+):([0-9]+) (.*) started$/)
    hour, min, comment = $1.to_i, $2.to_i, $3
    if hour < 12 && in_pm
      hour += 12
    end
    time = Time.local(DAY.year, DAY.month, DAY.day, hour, min
      ).strftime('%H:%M:%S')
  end

  am_on_break = false
  start_time, end_time, activity =
    case comment
      when 'now what?'
        am_on_break = true
        [time, nil, comment]
      when /^(start on|start to|start|now|switch to) (.*)$/
        [time, nil, $2]
      when 'back'
        if just_was_on_break
          [time, nil, logs.last && logs.last[2]]
        else
          [nil, time, logs.last && logs.last[2]]
        end
      when /^(done with that|done|great|break|take a break)$/
        am_on_break = true
        [nil, time, logs.last && logs.last[2]]
      when /^(was|done|done with|break from) (.*)$/
        am_on_break = true
        [nil, time, $2]
      when /^(off the phone with) (.*)$/
        [nil, time, "phone call with #{$2}"]
      else
        [time, nil, comment]
    end
  new_log = [start_time, end_time, activity]
  logs.push new_log

  just_was_on_break = am_on_break
}

logs.sort! { |log1, log2|
  (log1[0] || log1[1]) <=> (log2[0] || log2[1])
}

new_logs = []
logs.each { |log|
  if log[0].nil? &&
     new_logs.last && new_logs.last[1].nil? &&
     log[2] == new_logs.last[2]
    last_log = new_logs.pop # remove last log
    new_logs.push [last_log[0], log[1], log[2]]
  else
    new_logs.push log
  end
}
logs = new_logs

logs.each { |log|
  puts sprintf('%-10s %-10s %s', log[0], log[1], log[2])
}
