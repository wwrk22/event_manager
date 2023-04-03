require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'


@times = Array.new(24, 0)

def clean_phone_num(num)
  clean_num = ""
  num.each_char { |char| clean_num << char if char =~ /\d/ }

  if clean_num.length == 10
    return clean_num
  elsif clean_num.length == 11 && clean_num[0] == '1'
    return clean_num[1..10]
  else
    return "Invalid phone number"
  end
end


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end


def time_target(datetime)
  formatted_datetime = Time.strptime(datetime, "%m/%d/%y %H:%M")
  hour = formatted_datetime.hour
  @times[hour] += 1
end


def get_peak_hour
  max_with_index = @times.each_with_index.max
  max_with_index[1]
end


def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    return civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue Google::Apis::ClientError
    return "Failed to find representative for given inforamation. "\
    "Find your representative at "\
    "www.commoncause.org/take-action/find-elected-officials"
  end
end


def save_thank_you_letter(id, form_letter) 
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "./output/thanks_#{id}.html"
  File.open(filename, 'w') { |file| file.puts form_letter }
end

# Setup
puts "Event Manager initialized"

contents = CSV.open(
  './event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('./form_letter.erb')
erb_template = ERB.new template_letter

# Process data and write letters
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_num = clean_phone_num(row[:homephone])
  time_target(row[:regdate])

  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

contents.close

puts "Peak registration hour is #{get_peak_hour} o'clock."
