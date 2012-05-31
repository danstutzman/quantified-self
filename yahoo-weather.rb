#!/usr/bin/ruby
require 'net/http'
require 'rexml/document'
require 'parsedate'

WOEID = 12793015 # Boulder, CO 80302
url = "http://weather.yahooapis.com/forecastrss?w=#{WOEID}"
xml = Net::HTTP.get_response(URI.parse(url))

def safe(&block)
  begin
    block.call
  rescue Exception => e
    nil
  end
end

result_set = REXML::Document.new(xml.body)
out = {}
result_set.elements.each('rss/channel') do |element|
  element.elements.each('yweather:atmosphere') do |child|
    out['weather-humidity'] = safe { child.attributes['humidity'].to_i }
    out['weather-pressure'] = safe { child.attributes['pressure'].to_f }
    break
  end
  element.elements.each('yweather:astronomy') do |child|
    out['weather-sunrise-hour'] = safe {
      parts = ParseDate.parsedate(child.attributes['sunrise'])
      hours, minutes = parts[3], parts[4]
      sprintf('%.3f', hours + (minutes / 60.0))
    }
    out['weather-sunset-hour'] = safe {
      parts = ParseDate.parsedate(child.attributes['sunset'])
      hours, minutes = parts[3], parts[4]
      sprintf('%.3f', hours + (minutes / 60.0))
    }
    break
  end
  element.elements.each('item') do |item|
    item.elements.each('yweather:forecast') do |child|
      out['weather-temperature-high'] = safe { child.attributes['high'].to_i }
      out['weather-temperature-low'] = safe { child.attributes['low'].to_i }
      out['weather-condition-code'] = safe { child.attributes['code'].to_i }
      break
    end
    break
  end
  break
end

path = File.expand_path('../yahoo-weather.log', __FILE__)
today = Time.now.strftime('%Y-%m-%d')
File.open(path, 'a') { |file|
  out.each { |field, value|
    file.write "#{today},#{field},#{value}\n"
  }
}
