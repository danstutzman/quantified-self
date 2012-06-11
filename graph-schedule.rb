#!/usr/bin/env ruby
require 'rexml/document'
require 'parsedate'
require 'csv'

Y_SPACE_PER_HOUR = 30
X_SPACE_PER_DAY = 60
DAYS_SHOWN = 5

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
          tooltip.setAttributeNS(null,"x",evt.clientX+10);
          tooltip.setAttributeNS(null,"y",evt.clientY+30);
          tooltip.firstChild.data = evt.target.getAttributeNS(null,"mouseovertext");
          tooltip.setAttributeNS(null,"visibility","visible");
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

def add_rect(doc, day_num, start_time, finish_time, category, comments)
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
  rect.attributes['mouseovertext'] = comments
end

dates = {}
CSV.foreach('day-retrospective/logs.csv') { |row|
  next if row[0].match(/^What /)
  next if row[0] == 'Date' # column headers
  date, start, finish, category, comment = row
  datetime = Time.gm(*ParseDate.parsedate(date))
  dates[datetime] = true
}
num_days = ((dates.keys.max - dates.keys.min) / (24 * 60 * 60.0)) + 2

doc = REXML::Document.new(
  '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" onload="init(evt)"></svg>')
add_interactivity(doc)
add_x_axis(doc, num_days)
add_y_axis(doc, num_days)

CSV.foreach('day-retrospective/logs.csv') { |row|
  next if row[0].match(/^What /)
  next if row[0] == 'Date' # column headers
  date, start, finish, category, comment = row
  start.gsub! /\?$/, ''
  finish.gsub! /\?$/, ''
  datetime = Time.gm(*ParseDate.parsedate(date))
  dates[datetime] = true
  day_num = (datetime - Time.gm(2012, 5, 26)) / (60 * 60 * 24)
  _, _, _, h, m, s = ParseDate.parsedate(start)
  start_time = Time.gm(1970, 1, 1, h, m, s)
  _, _, _, h, m, s = ParseDate.parsedate(finish)
  finish_time = Time.gm(1970, 1, 1, h, m, s)

  add_rect(doc, day_num, start_time, finish_time, category, comment)
}

CSV.foreach('parse-zeo.log') { |row|
  date, key, value = row
  if key == 'zeo-start-of-night-hour'
    datetime = Time.gm(*ParseDate.parsedate(date))
    day_num = (datetime - Time.gm(2012, 5, 26)) / (60 * 60 * 24)
    start_time = Time.gm(1970, 1, 1).to_i + value.to_f * 3600
    finish_time = Time.gm(1970, 1, 2).to_i
    add_rect(doc, day_num, start_time, finish_time, 'sleep', 'sleep')
  end
  if key == 'zeo-end-of-night-hour'
    datetime = Time.gm(*ParseDate.parsedate(date))
    day_num = (datetime - Time.gm(2012, 5, 26)) / (60 * 60 * 24) + 1
    start_time = Time.gm(1970, 1, 1).to_i
    finish_time = Time.gm(1970, 1, 1).to_i + (value.to_f - 24) * 3600
    add_rect(doc, day_num, start_time, finish_time, 'sleep', 'sleep')
  end
}

dates.keys.sort.each { |datetime|
  day_num = (datetime - Time.gm(2012, 5, 26)) / (60 * 60 * 24)

  g = doc[0].add_element('g')
  x = day_num * X_SPACE_PER_DAY
  midnight = Time.gm(1970, 1, 2, 0, 0, 0).to_i / (60 * 60) * Y_SPACE_PER_HOUR
  g.attributes['transform'] = "translate(#{x + 0.5}, #{midnight})"
  text = g.add_element('text')
  text.attributes['transform'] = 'rotate(90)'
  text.text = datetime.strftime('%Y-%m-%d')
  text.attributes['x'] =  5 # displaces by y because of the transform
  text.attributes['y'] = -5 # displaces by x because of the transform
}

# add tooltip at the end so it shows on top
text = doc[0].add_element('text')
text.attributes['id'] = 'tooltip'
text.attributes['x'] = 0
text.attributes['y'] = 0
text.attributes['visibility'] = 'hidden'
text.text = 'Tooltip'

puts doc
