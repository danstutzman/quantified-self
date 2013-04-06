#!/usr/bin/ruby

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

def parsedate(string)
  if match = string.match(/^([0-9]{2})\/([0-9]{2})\/([0-9]{4})$/)
    [match[3].to_i, match[1].to_i, match[2].to_i, 0, 0, 0]
  elsif match = string.match(/^([0-9]{2})\/([0-9]{2})\/([0-9]{4}) ([0-9]{2}):([0-9]{2})$/)
    [match[3].to_i, match[1].to_i, match[2].to_i, match[4].to_i, match[5].to_i, 0]
  else
    raise "Can't parse date #{string}"
  end

  #match = string.match(
  #  /([0-9]{4})-([0-9]{2})-([0-9]{2}) [0-9]{2}:[0-9]{2}:[0-9]{2}/) \
  #  or raise "Bad datetime #{string}"
  #[match[1].to_i, match[2].to_i, match[3].to_i,
  # match[4].to_i, match[5].to_i, match[6].to_i]
end

def subtract_dates(later_date, date)
  y, m, d, h, min, s = parsedate(later_date)
  hour = (Time.local(y, m, d, h, min, s) - date).to_i / 3600.0
  sprintf('%.2f', hour)
end

File.open(File.expand_path('../data/parse-zeo.log', __FILE__), 'w') { |out_file|
  File.open(File.expand_path('../data/zeodata.csv', __FILE__)) { |in_file|
    headers = in_file.readline.split(',')
    headers.reject! { |header| header.match(/^SS/) }
    in_file.each_line { |line|
      values = line.split(',')
      y, m, d = parsedate(values[headers.index('Sleep Date')])
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
