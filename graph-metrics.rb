#!/usr/bin/env ruby
require 'rexml/document'
require 'parsedate'

SPACE_PER_DATE = 30
SPACE_PER_KEY = 20
LEFT_MARGIN = 250
LABEL_X = 220

dates = {}
keys = {}
date2key2value = {}
Dir.glob('*.log') { |filename|
  File.open(filename) { |file|
    file.each_line { |line|
      date, key, value = line.split(',')
      next if Time.local(*ParseDate.parsedate(date)) < Time.local(2012, 5, 25)
      date = Time.local(*ParseDate.parsedate(date)).to_i / (60 * 60 * 24)
    
      if date2key2value[date].nil?
        date2key2value[date] = {}
      end
      date2key2value[date][key] = value
    
      dates[date] = true
      keys[key] = true
    }
  }
}
dates = dates.keys.sort
keys = keys.keys.sort
min_date = dates.min
max_date = dates.max

key2min_value = {}
key2max_value = {}
keys.each { |key|
  dates.each { |date|
    value = date2key2value[date][key]
    if value
      value = value.to_f
      if key2min_value[key].nil? ||
         value < key2min_value[key]
        key2min_value[key] = value
      end
      if key2max_value[key].nil? ||
         value > key2max_value[key]
        key2max_value[key] = value
      end
    end
  }
}
$key2min_value = key2min_value
$key2max_value = key2max_value

def value_to_y(key, value)
  #-value / 3.0
  ((value - $key2min_value[key]) * (-SPACE_PER_KEY * 1 / 2) /
    ($key2max_value[key] - $key2min_value[key])) + 5
end

doc = REXML::Document.new(
  '<svg xmlns="http://www.w3.org/2000/svg" version="1.1"></svg>')
keys.each_with_index { |key, i|
  g = doc[0].add_element('g')
  g.attributes['transform'] = "translate(0, #{i * SPACE_PER_KEY + 45})"

  text = g.add_element('text')
  text.attributes['x'] = LABEL_X
  text.attributes['y'] = 0
  text.attributes['text-anchor'] = 'end'
  text.text = key

  earliest_date = date2key2value.keys.select { |date|
    date2key2value[date][key]
  }.min
  earliest_value = date2key2value[earliest_date][key]
  label0 = g.add_element('text')
  label0.attributes['x'] =
    LEFT_MARGIN + (earliest_date - min_date) * SPACE_PER_DATE
  label0.attributes['y'] = value_to_y(key, earliest_value.to_f)
  label0.attributes['text-anchor'] = 'end'
  label0.attributes['style'] = 'font-size:10'
  label0.text = earliest_value

  latest_date = date2key2value.keys.select { |date|
    date2key2value[date][key]
  }.max
  latest_value = date2key2value[latest_date][key]
  label1 = g.add_element('text')
  label1.attributes['x'] =
    LEFT_MARGIN + (latest_date - min_date) * SPACE_PER_DATE
  label1.attributes['y'] = value_to_y(key, latest_value.to_f)
  label1.attributes['style'] = 'font-size:10'
  label1.text = latest_value

  polyline = g.add_element('polyline')
  polyline.attributes['style'] = "fill:none;stroke:black"
  points = []
  (min_date..max_date).each { |date|
    value = (date2key2value[date] || {})[key]
    if value
      x = (date - min_date) * SPACE_PER_DATE + LEFT_MARGIN
      y = value_to_y(key, value.to_f)
      points.push "#{x},#{y}"
    end
  }
  polyline.attributes['points'] = points.join(' ')
}

(min_date..max_date).each { |date|
  x = (date - min_date) * SPACE_PER_DATE + LEFT_MARGIN

  line = doc[0].add_element('line')
  line.attributes['x1'] = x + 0.5
  line.attributes['x2'] = x + 0.5
  line.attributes['y1'] = 0
  line.attributes['y2'] = keys.size * SPACE_PER_KEY + 45
  line.attributes['style'] = 'stroke:rgb(0,0,0);stroke-width:0.5'

  g = doc[0].add_element('g')
  g.attributes['transform'] =
    "translate(#{x + 0.5}, #{keys.size * SPACE_PER_KEY + 45})"
  text = g.add_element('text')
  text.attributes['transform'] = 'rotate(90)'
  text.text = Time.at(date * 60 * 60 * 24).strftime('%Y-%b-%d')
  text.attributes['x'] = 40 # displaces by y because of the transform
  text = g.add_element('text')
  text.attributes['transform'] = 'rotate(90)'
  text.text = Time.at(date * 60 * 60 * 24).strftime('%a')
  text.attributes['x'] = 5 # displaces by y because of the transform
}

puts doc
