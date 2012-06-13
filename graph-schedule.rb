#!/usr/bin/env ruby
require 'rexml/document'
require 'parsedate'
require 'csv'
require 'date'

Y_SPACE_PER_HOUR = 30
X_SPACE_PER_DAY = 60
DAYS_SHOWN = 5
DATA_PATH = File.expand_path('../data/actions.sqlite3', __FILE__)
ZEO_PATH = File.expand_path('../data/parse-zeo.log', __FILE__)

def string_to_date(string)
  match = string.match(/([0-9]{4})-([0-9]{2})-([0-9]{2})/) \
    or raise "Bad date #{string}"
  date = Date.new(match[1].to_i, match[2].to_i, match[3].to_i)
end

def add_interactivity(doc)
  script = doc[0].add_element('script')
  script.attributes['type'] = 'text/ecmascript'
  script.text = '
      function init(evt) {
          if ( window.svgDocument == null ) {
              svgDocument = evt.target.ownerDocument;
          }
          tooltip = svgDocument.getElementById("tooltip");
      }
  
      function ShowTooltip(evt) {
          // Put tooltip in the right position, change the text and make it visible
          var translateX = evt.clientX + 10;
          var translateY = evt.clientY;
          var transform = "translate(" + translateX + "," + translateY + ")";
          tooltip.setAttributeNS(null, "transform", transform);
          var text = tooltip.childNodes[1];
          text.firstChild.data = evt.target.getAttributeNS(null,"mouseovertext");
          tooltip.setAttributeNS(null,"visibility","visible");
          var rect = tooltip.childNodes[0];
          rect.setAttributeNS(null, "width", text.getBBox().width);
      }
  
      function HideTooltip(evt) {
          tooltip.setAttributeNS(null,"visibility","hidden");
      }
  '
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

def add_rect(doc, day_num, start_time, finish_time, category, tooltip)
  y0 = start_time.to_f / (60 * 60) * Y_SPACE_PER_HOUR
  y1 = finish_time.to_f / (60 * 60) * Y_SPACE_PER_HOUR

  color = case category
    when /^dev/    then 'blue'
    when /^body/   then 'red'
    when /^social/ then 'orange'
    when 'work'    then 'green'
    when 'sleep'   then 'black'
    else 'white'
  end

  rect = doc[0].add_element('rect')
  rect.attributes['x'] = day_num * X_SPACE_PER_DAY
  rect.attributes['width'] = X_SPACE_PER_DAY * 0.8
  rect.attributes['y'] = y0
  rect.attributes['height'] = y1 - y0
  rect.attributes['style'] = "stroke:black;fill:#{color};"
  rect.attributes['onmousemove'] = "ShowTooltip(evt)"
  rect.attributes['onmouseout'] = "HideTooltip(evt)"
  rect.attributes['mouseovertext'] = tooltip
end

class Action
  attr_accessor :start, :finish, :category, :comment
  def initialize(*args)
    @start, @finish, @category, @comment = args
  end
end

date_to_actions = {}
sqlite_out = `echo 'select * from actions;' | sqlite3 data/actions.sqlite3`
sqlite_out.split("\n").each { |line|
  id, date_string, start, finish, category, comment = line.strip.split('|')
  date = string_to_date(date_string)

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
  version="1.1" onload="init(evt)"></svg>')
add_interactivity(doc)
add_x_axis(doc, num_days)
add_y_axis(doc, num_days)

date_to_actions.keys.sort.each { |date|
  actions = date_to_actions[date]
  actions.each { |action|
    day_num = (date - min_date)
    _, _, _, h, m, s = ParseDate.parsedate(action.start)
    start_time = Time.gm(1970, 1, 1, h, m, s)
    _, _, _, h, m, s = ParseDate.parsedate(action.finish)
    finish_time = Time.gm(1970, 1, 1, h, m, s)
  
    add_rect(doc, day_num, start_time, finish_time,
      action.category, "#{action.category} #{action.comment}")
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
    add_rect(doc, day_num, start_time, finish_time, 'sleep', 'sleep')
  elsif start < 24 && finish >= 24
    add_rect(doc, day_num, start_time, midnight_end, 'sleep', 'sleep')
    add_rect(doc, day_num + 1, midnight_begin, finish_time, 'sleep', 'sleep')
  elsif start >= 24
    add_rect(doc, day_num + 1, start_time - 24 * 3600, finish_time, 'sleep', 'sleep')
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

puts doc
