#!/usr/bin/ruby
require 'parsedate'
require 'csv'

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

class Log
  attr_accessor *%w[
    start
    finish
    comment
    contributing_actions
    is_start_tentative
    is_finish_tentative
  ]
  def initialize(*args)
    raise "Expected 3 args, got #{args.size}" if args.size != 3
    @start, @finish, @comment = args
    @contributing_actions = []
    @is_start_tentative, @is_finish_tentative = false, false
  end
end

lines = []
File.open(File.expand_path('../../actions.txt', __FILE__)) { |file|
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

  contributing_actions = [line.join(' ')]
  if comment == 'no'
    if logs.last.comment.nil?
      previous_log = logs.pop
      contributing_actions =
        previous_log.contributing_actions + contributing_actions
    end
    next
  elsif comment.match(/^actually (.*)$/)
    if logs.last.comment.nil?
      previous_log = logs.pop
      contributing_actions =
        previous_log.contributing_actions + contributing_actions
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
  new_log = case comment
    when 'now what?'
      Log.new(time, nil, comment)
    when /^(start on|start to|start|now|switch to) (.*)$/
      Log.new(time, nil, $2)
    when 'back'
      if just_was_on_break
        Log.new(time, nil, logs.last && logs.last.comment)
      else
        Log.new(nil, time, logs.last && logs.last.comment)
      end
    when /^(done with that|done|great|break|take a break)$/
      am_on_break = true
      Log.new(nil, time, logs.last && logs.last.comment)
    when /^(was|done|done with|break from) (.*)$/
      am_on_break = true
      Log.new(nil, time, $2)
    when /^(off the phone with) (.*)$/
      Log.new(nil, time, "phone call with #{$2}")
    else
      Log.new(time, nil, comment)
  end
  new_log.contributing_actions = contributing_actions
  logs.push new_log

  just_was_on_break = am_on_break
}

logs.sort! { |log1, log2|
  (log1.start || log1.finish) <=> (log2.start || log2.finish)
}

new_logs = []
logs.each { |log|
  if log.start.nil? &&
     new_logs.last && new_logs.last.finish.nil? &&
     log.comment == new_logs.last.comment
    last_log = new_logs.pop # remove last log
    new_log = Log.new(last_log.start, log.finish, log.comment)
    new_log.contributing_actions = last_log.contributing_actions +
      log.contributing_actions
    new_logs.push new_log
  else
    new_logs.push log
  end
}
logs = new_logs

last_finish = '00:00:00'
logs.each_with_index { |log, i|
  if log.start.nil?
    log.start = last_finish
    log.is_start_tentative = true
  end
  if log.finish.nil?
    log.finish = logs[i + 1] ? logs[i + 1].start : (log.start || last_finish)
    log.is_finish_tentative = true
  end
  last_finish = log.finish || log.start || last_finish
}

if false
logs.each { |log|
  puts sprintf('%8s%s  %8s%s   %s',
    log.start,  log.start && log.is_start_tentative ? '?' : ' ',
    log.finish, log.finish && log.is_finish_tentative ? '?' : ' ',
    log.comment)
  #log.contributing_actions.each { |action|
  #  puts sprintf('%25s%s', '', action)
  #}
}
end

date = DAY.strftime('%Y-%m-%d')
File.open(File.expand_path('../logs.csv', __FILE__), 'a') { |file|
  CSV::Writer.generate(file) { |csv|
    logs.each { |log|
      csv << [date,
        (log.start || '') +
        ((log.start && log.is_start_tentative) ? '?' : ''),
        (log.finish || '') +
        ((log.finish && log.is_finish_tentative) ? '?' : ''),
        '',
        log.comment
      ]
    }
  }
}
