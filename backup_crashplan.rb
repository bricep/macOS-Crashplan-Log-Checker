#!/usr/bin/ruby
require 'time'

## Configuration variables
too_old_threshold = (86400 * 3)
LOG_FILE = "/Library/Logs/CrashPlan/backup_files.log.0"
LOG_FILE2 = "/Library/Logs/CrashPlan/backup_files.log"

## Declaration of variables
last_successful_time = Time.at(0)
last_completion_time = Time.at(0)
last_failure_time = Time.at(-1)

## Creates an array of "events" from the log file

if File.exist?(LOG_FILE)
    events=File.open(LOG_FILE, 'r').readlines
elsif File.exist?(LOG_FILE2)
    events=File.open(LOG_FILE2, 'r').readlines
else
  puts "The file \"#{LOG_FILE}\" does not exist."
  exit 1001
end


## Validates and parses date/time strings in the format of "%m/%d/%y %I:%M%p".

def parse_time(datetime_string)
  if datetime_string =~ /^(?=\d)(?:(?:(?:(?:(?:0?[13578]|1[02])(\/|-|\.)31)\1|(?:(?:0?[1,3-9]|1[0-2])(\/|-|\.)(?:29|30)\2))(?:(?:1[6-9]|[2-9]\d)?\d{2})|(?:0?2(\/|-|\.)29\3(?:(?:(?:1[6-9]|[2-9]\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))|(?:(?:0?[1-9])|(?:1[0-2]))(\/|-|\.)(?:0?[1-9]|1\d|2[0-8])\4(?:(?:1[6-9]|[2-9]\d)?\d{2}))($|\ (?=\d)))?(((0?[1-9]|1[012])(:[0-5]\d){0,2}([AP]M))|([01]\d|2[0-3])(:[0-5]\d){1,2})?$/
    month = datetime_string.split(/[\s,\/]/)[0]
    day = datetime_string.split(/[\s,\/]/)[1]
    year = datetime_string.split(/[\s,\/]/)[2]
    time_string = datetime_string.split(/[\s,\/]/)[3]
    actual_time = Time.parse("#{year}-#{month}-#{day} #{time_string}")
  elsif datetime_string == ""
      actual_time = Time.at(0)
  else
    puts "Error parsing log. \"#{datetime_string}\" is not the proper date format."
    exit 1001
  end
  return actual_time
end

## Parses the log line by line to determine completion, success, failures
events.each do |event|
  if event[0,1] == "W"
    last_failure_time = parse_time(event[2..17])
  end
  if (event[0,1] == "I" and event.include? "Completed backup to CrashPlan")
    if last_completion_time > last_failure_time
      last_successful_time = parse_time(event[2..17])
    end
    last_completion_time = parse_time(event[2..17])
  end
end

## Determines success/failure based on completion, success, and failure times
if last_completion_time == Time.at(0)
  puts "Backup has never completed."
  exit 1001
elsif last_successful_time == Time.at(0)
  puts "Backup has never been successful. Last completion: #{last_completion_time.strftime("%F, %T")}."
  exit 1001
elsif (Time.now - last_completion_time) > too_old_threshold
  puts "Last backup is old. Last completion: #{last_completion_time.strftime("%F, %T")}."
  exit 1001
elsif (Time.now - last_successful_time) > too_old_threshold
  puts "Last successful backup is old. Last success: #{last_successful_time.strftime("%F, %T")}."
  exit 1001
elsif last_completion_time > last_successful_time
  puts "Last backup had errors. Last success: #{last_successful_time.strftime("%F, %T")}."
  exit 0
else
  puts "Last backup was successful. Last success: #{last_successful_time.strftime("%F, %T")}."
  exit 0
end
