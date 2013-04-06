require 'rexml/document'
require 'csv'
require 'date'

Y_SPACE_PER_HOUR = 30
X_SPACE_PER_DAY = 60
DAYS_SHOWN = 5
DATA_PATH = File.expand_path('data.sqlite3', __FILE__)
ZEO_PATH = File.expand_path('../../data/parse-zeo.log', __FILE__)

def string_to_date(string)
  match = string.match(/([0-9]{4})-([0-9]{2})-([0-9]{2})/) \
    or raise "Bad date #{string}"
  date = Date.new(match[1].to_i, match[2].to_i, match[3].to_i)
end

def datetime_to_date(string)
  match = string.match(
    /([0-9]{4})-([0-9]{2})-([0-9]{2}) [0-9]{2}:[0-9]{2}:[0-9]{2}/) \
    or raise "Bad datetime #{string}"
  date = Date.new(match[1].to_i, match[2].to_i, match[3].to_i)
end

def datetime_to_hms(date, datetime)
  match = datetime.match(
    /([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})/) \
    or raise "Bad datetime #{string}"
  #if match[1].to_i != date.year ||
  #   match[2].to_i != date.month ||
  #   match[3].to_i != date.day
  #  raise "Datetime doesn't match date: #{[datetime, date].inspect}"
  #end
  [match[4].to_i, match[5].to_i, match[6].to_i]
end

def add_x_axis(doc, num_days)
  y0 = Time.gm(1970, 1, 1, 0, 0, 0).to_i / (60 * 60) * Y_SPACE_PER_HOUR
  y1 = Time.gm(1970, 1, 2, 0, 0, 0).to_i / (60 * 60) * Y_SPACE_PER_HOUR
  (0...num_days).each { |day_num|
    line = doc[0].add_element('line')
    line.attributes['x1'] = (day_num + 0.5) * X_SPACE_PER_DAY
    line.attributes['x2'] = (day_num + 0.5) * X_SPACE_PER_DAY
    line.attributes['y1'] = y0
    line.attributes['y2'] = y1
    line.attributes['style'] = 'stroke:black'
  }
end

def add_y_axis(doc, num_days)
  (0...24).each { |hour|
    next unless hour % 2 == 0
  
    datetime = Time.gm(1970, 1, 1, hour, 0, 0)
    y = datetime.to_i / (60 * 60) * Y_SPACE_PER_HOUR
  
    line = doc[0].add_element('line')
    line.attributes['x1'] = 0
    line.attributes['x2'] = X_SPACE_PER_DAY * num_days
    line.attributes['y1'] = y
    line.attributes['y2'] = y
    line.attributes['style'] = 'stroke:black;stroke-width:0.5'
  
    text = doc[0].add_element('text')
    text.text = datetime.strftime('%H:%M')
    text.attributes['x'] = X_SPACE_PER_DAY * num_days
    text.attributes['y'] = y + 5
  }
end

def add_rect(doc, day_num, start_time, finish_time, action)
  y0 = start_time.to_f / (60 * 60) * Y_SPACE_PER_HOUR
  y1 = finish_time.to_f / (60 * 60) * Y_SPACE_PER_HOUR

  color = case action.category
    when 'domestic'       then 'pink'
    when 'work'           then 'green'
    when 'sleep'          then 'black'
    when 'improve'        then 'yellow'
    when 'zone-out'       then 'gray'
    when 'virtual-social' then 'blue'
    when 'real-social'    then 'orange'
    when 'exercise'       then 'red'
    else 'white'
  end
  tooltip = action.comment

  rect = doc[0].add_element('rect')
  rect.attributes['x'] = day_num * X_SPACE_PER_DAY
  rect.attributes['width'] = X_SPACE_PER_DAY * 0.8
  rect.attributes['y'] = y0
  rect.attributes['height'] = y1 - y0
  rect.attributes['style'] = "stroke:black;fill:#{color};"
  tooltip_element = rect.add_element('title')
  tooltip_element.text = tooltip
end

class Action
  attr_accessor :start, :finish, :category, :comment
  def initialize(*args)
    @start, @finish, @category, @comment = args
  end
end
SLEEP = Action.new(nil, nil, 'sleep', '')

date_to_actions = {}
sqlite_out = `echo "select id, start_date, finish_date, category, intention from logs where intention != '';" | sqlite3 data.sqlite3`
sqlite_out.split("\n").each { |line|
  id, start, finish, category, comment = line.strip.split('|')
  date = datetime_to_date(start)

  action = Action.new(start, finish, category, comment)
  if date_to_actions[date].nil?
    date_to_actions[date] = []
  end
  date_to_actions[date].push action
}
min_date = date_to_actions.keys.min
max_date = date_to_actions.keys.max
num_days = (max_date - min_date).ceil + 1

doc = REXML::Document.new('<svg xmlns="http://www.w3.org/2000/svg"
  version="1.1"></svg>')
add_x_axis(doc, num_days)
add_y_axis(doc, num_days)

date_to_actions.keys.sort.each { |date|
  actions = date_to_actions[date]
  actions.each { |action|
    day_num = (date - min_date).to_i
    h, m, s = datetime_to_hms(date, action.start)
    start_time = Time.gm(1970, 1, 1, h, m, s)
    h, m, s = datetime_to_hms(date, action.finish)
    finish_time = Time.gm(1970, 1, 1, h, m, s)

    if finish_time < start_time
      new_finish_time = Time.gm(1970, 1, 1, 23, 59, 59)
      add_rect(doc, day_num, start_time, new_finish_time, action)

      new_start_time = Time.gm(1970, 1, 1, 0, 0, 0)
      add_rect(doc, day_num + 1, new_start_time, finish_time, action)
    else
      add_rect(doc, day_num, start_time, finish_time, action)
    end
  }
}

date_to_start_sleep = {}
date_to_finish_sleep = {}
CSV.foreach(ZEO_PATH) { |row|
  date, key, value = row
  if key == 'zeo-start-of-night-hour'
    date_to_start_sleep[string_to_date(date)] = value.to_f
  end
  if key == 'zeo-end-of-night-hour'
    date_to_finish_sleep[string_to_date(date)] = value.to_f
  end
}

(min_date..max_date).each { |date|
  day_num = (date - min_date).floor
  start, finish = date_to_start_sleep[date], date_to_finish_sleep[date]
  midnight_begin = Time.gm(1970, 1, 1).to_i
  start_time = Time.gm(1970, 1, 1).to_i + start.to_f * 3600
  midnight_end = Time.gm(1970, 1, 2).to_i
  finish_time = Time.gm(1970, 1, 1).to_i + (finish.to_f - 24) * 3600
  if start.nil? || finish.nil?
  elsif finish < 24 # wake up before midnight
    add_rect(doc, day_num, start_time, finish_time, SLEEP)
  elsif start < 24 && finish >= 24
    add_rect(doc, day_num, start_time, midnight_end, SLEEP)
    add_rect(doc, day_num + 1, midnight_begin, finish_time, SLEEP)
  elsif start >= 24
    add_rect(doc, day_num + 1, start_time - 24 * 3600, finish_time, SLEEP)
  end
}

date_to_actions.keys.sort.each { |date|
  day_num = (date - min_date).floor

  g = doc[0].add_element('g')
  x = day_num * X_SPACE_PER_DAY
  midnight = Time.gm(1970, 1, 2, 0, 0, 0).to_i / (60 * 60) * Y_SPACE_PER_HOUR
  g.attributes['transform'] = "translate(#{x + 0.5}, #{midnight})"
  text = g.add_element('text')
  text.attributes['transform'] = 'rotate(90)'
  text.text = date.strftime('%Y-%m-%d')
  text.attributes['x'] =  5 # displaces by y because of the transform
  text.attributes['y'] = -5 # displaces by x because of the transform
}

# add tooltip at the end so it shows on top
g = doc[0].add_element('g')
g.attributes['id'] = 'tooltip'
g.attributes['visibility'] = 'hidden'

rect = g.add_element('rect')
rect.attributes['id'] = 'tooltip'
rect.attributes['x'] = 0
rect.attributes['y'] = 0
rect.attributes['width'] = 100
rect.attributes['height'] = 20
rect.attributes['fill'] = 'white'

text = g.add_element('text')
text.attributes['id'] = 'tooltip'
text.attributes['x'] = 0
text.attributes['y'] = 20
text.text = 'Tooltip'

#puts doc

formatter = REXML::Formatters::Pretty.new(2)
formatter.compact = true # This is the magic line that does what you need!
formatter.write(doc, $stdout)
