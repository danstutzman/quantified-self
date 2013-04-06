require 'rexml/document'
require 'csv'
require 'date'

Y_SPACE_PER_HOUR = 30
X_SPACE_PER_DAY = 60
DAYS_SHOWN = 5
DATA_PATH = File.expand_path('data.sqlite3', __FILE__)
ZEO_PATH = File.expand_path('../../data/zeodata.csv', __FILE__)

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
    when 'zeo1'           then '#420' # orange = wake
    when 'zeo2'           then '#040' # light green=rem
    when 'zeo3'           then '#222' # gray=light
    when 'zeo4'           then '#006' # dark green=deep, change to blue
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
  #rect.attributes['style'] = "stroke:black;fill:#{color};"
  rect.attributes['style'] = "fill:#{color};"
  tooltip_element = rect.add_element('title')
  tooltip_element.text = tooltip
end

class Action
  attr_accessor :start, :finish, :category, :comment
  def initialize(*args)
    @start, @finish, @category, @comment = args
  end
end

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

def parsedate(string)
  if match = string.match(/^([0-9]{2})\/([0-9]{2})\/([0-9]{4})$/)
    [match[3].to_i, match[1].to_i, match[2].to_i, 0, 0, 0]
  elsif match = string.match(/^([0-9]{2})\/([0-9]{2})\/([0-9]{4}) ([0-9]{2}):([0-9]{2})$/)
    [match[3].to_i, match[1].to_i, match[2].to_i, match[4].to_i, match[5].to_i, 0]
  else
    raise "Can't parse date #{string}"
  end
end

File.open(ZEO_PATH) do |in_file|
  headers = in_file.readline.split(',')
  headers.reject! { |header| header.match(/^SS/) }
  in_file.each_line do |line|
    values = line.split(',')
    y, m, d = parsedate(values[headers.index('Sleep Date')])
    date = Time.local(y, m, d)
    next if date.year < 2012
    #start = parsedate(values[9])
    #start_time = Time.gm(1970, 1, 1, start[3], start[4], start[5])
    finish = parsedate(values[11])
    finish_time = Time.gm(1970, 1, 2, finish[3], finish[4], finish[5])

    day_num = (Date.new(y, m, d) - min_date).to_i
    #action = Action.new(start_time, finish_time, 'zeo', 'zeo')
    #if start_time < finish_time
    #  add_rect(doc, day_num, start_time, finish_time, action)
    #else
    #  new_finish_time = Time.gm(1970, 1, 1, 23, 59, 59)
    #  add_rect(doc, day_num, start_time, new_finish_time, action)
    #
    #  new_start_time = Time.gm(1970, 1, 1, 0, 0, 0)
    #  add_rect(doc, day_num + 1, new_start_time, finish_time, action)
    #end


    # 74 is by 5 mins
    # 75 is by 30 seconds
    # 0 undefined, 1 - Wake, 2 - REM, 3 - Light, 4 - Deep

    blocks = values[74].split(' ').map { |i| i.to_i }
    # remove final 0 elements (sleep_type = undefined)
    while blocks.size > 0 && blocks.last == 0
      blocks.pop
    end

    start_time = finish_time - (blocks.size * 5 * 60)
    blocks.each_with_index do |sleep_type, i|
      new_start_time = start_time + (i * 5 * 60)
      new_finish_time = new_start_time + (1 * 5 * 60)
      if sleep_type != 0 # don't log undefined
        if new_start_time.day == 2 # wrapped over to Jan 2
          new_start_time -= (60 * 60 * 24)
          new_finish_time -= (60 * 60 * 24)
          action = Action.new(
            new_start_time, new_finish_time, "zeo#{sleep_type}", 'zeo')
          add_rect(doc, day_num + 1, new_start_time, new_finish_time, action)
        else
          action = Action.new(
            new_start_time, new_finish_time, "zeo#{sleep_type}", 'zeo')
          add_rect(doc, day_num, new_start_time, new_finish_time, action)
        end
      end
    end
  end
end

date_to_actions.keys.sort.each { |date|
  day_num = (date - min_date).floor

  g = doc[0].add_element('g')
  x = day_num * X_SPACE_PER_DAY
  midnight = Time.gm(1970, 1, 2, 0, 0, 0).to_i / (60 * 60) * Y_SPACE_PER_HOUR
  g.attributes['transform'] = "translate(#{x + 0.5}, #{midnight})"
  text = g.add_element('text')
  text.attributes['transform'] = 'rotate(90)'
  text.text = date.strftime('%a, %b-%d')
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
