puts "Event Manager initialized"

# 1. Load the file
filename = './event_attendees.csv'

if File.exists? filename
  file = File.open('./event_attendees.csv')
  event_attendees = file.readlines
else
  puts "Error: #{filename} does not exist."
end

# Skip the header row at index 0.
event_attendees[1..].each do |line|
  columns = line.split(',')
  name = columns[2]
  p(name + "\n")
end
