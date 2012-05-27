#!/usr/bin/ruby
require 'parsedate'

date_to_habit_counts = {}
File.open('track-bad-habit.txt') { |in_file|
  in_file.each_line { |line|
    timestamp = line.split(',')[0]
    habit_num = line.split(',')[1].strip.to_i

    y, m, d = ParseDate.parsedate(timestamp)
    date = Time.local(y, m, d)
    if date_to_habit_counts[date].nil?
      date_to_habit_counts[date] = Hash.new(0)
    end
    date_to_habit_counts[date][habit_num] += 1
  }
}

File.open('parse-bad-habits.log', 'w') { |out_file|
  min_date = date_to_habit_counts.keys.min
  max_date = date_to_habit_counts.keys.max
  date = min_date
  while date.to_i <= max_date.to_i
    date_out = date.strftime('%Y-%m-%d')
    date_to_habit_counts[date].each { |habit_num, num_reps|
      out_file.write "#{date_out},count-habit-reps-#{habit_num},#{num_reps}\n"
    }
    date += 1
  end
}
