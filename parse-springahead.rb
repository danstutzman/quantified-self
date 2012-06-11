#!/usr/bin/ruby

month = 5 # May
month_adjust = -1 # start with previous month
out_path = File.expand_path('../data/springahead-2012-may.log', __FILE__)
File.open(out_path, 'w') { |out_file|
  File.open('data/springahead-2012-may.txt') { |in_file|
    done = false
    in_file.each_line { |line|
      break if done
      if line.match(/^[0-9]+$/)
        line.gsub! /Today/, ''
        line2 = in_file.readline.strip
        7.times {
          day_num = line.to_i
          if line2.to_i == (day_num + 1)
            # then line2 is actually a day number
            done = true
            break
          end

          if match = line2.match(/^([0-9]+)(:([0-9]+))?$/)
            hours, mins = match[1].to_i, match[3].to_i
            hours_worked = hours + (mins / 60.0)
          elsif line2.strip == '-'
            hours_worked = 0.0
          else
            done = true
            break
          end
          hours_worked = sprintf('%.2f', hours_worked)

          line, line2 = in_file.readline.strip, in_file.readline.strip
          line.gsub! /Today/, ''

          if day_num == 1
            month_adjust += 1
          end
          date = Time.local(2012, month + month_adjust, day_num)
          date = date.strftime('%Y-%m-%d')
          out_file.write "#{date},springahead-hours-worked,#{hours_worked}\n"
        }
      end
    }
  }
}
