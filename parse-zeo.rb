#!/usr/bin/ruby
require 'parsedate'

FIELD_NAMES = %w[
  ZQ
  Total-Z
  Time-to-Z
  Time-in-Wake
  Time-in-REM
  Time-in-Light
  Time-in-Deep
  Awakenings
]

def subtract_dates(later_date, date)
  y, m, d, h, min, s = ParseDate.parsedate(later_date)
  hour = (Time.local(y, m, d, h, min, s) - date).to_i / 3600.0
  sprintf('%.2f', hour)
end

File.open(File.expand_path('../parse-zeo.log', __FILE__), 'w') { |out_file|
  File.open('/Users/dstutzman/Desktop/zeodata.csv') { |in_file|
    headers = in_file.readline.split(',')
    headers.reject! { |header| header.match(/^SS/) }
    in_file.each_line { |line|
      values = line.split(',')
      y, m, d = ParseDate.parsedate(values[headers.index('Sleep Date')])
      date = Time.local(y, m, d)
      next if date.year < 2012

      out = {}
      FIELD_NAMES.each { |field_name|
        value = values[headers.index(field_name.gsub('-', ' '))]
        out["zeo-#{field_name.downcase}"] = value
      }
      out['zeo-start-of-night-hour'] =
        subtract_dates(values[headers.index('Start of Night')], date)
      out['zeo-end-of-night-hour'] =
        subtract_dates(values[headers.index('End of Night')], date)

      out.each { |name, value|
        out_file.write "#{date.strftime('%Y-%m-%d')},#{name},#{value}\n"
      }
    }
  }
}
