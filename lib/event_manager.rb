require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'


@hours = Array.new(24, 0)
@days = Array.new(7, 0)

def filter_number(number)
  number.each_char.reduce("") do |clean_number, digit|
    (digit =~ /\d/) ? (clean_number << digit) : clean_number
  end 
end


def fix_filtered_number(filtered_number)
  return filtered_number if filtered_number.length == 10
  has_intl_code = filtered_number.length == 11 && filtered_number[0] == '1'
  return filtered_number[1..10] if has_intl_code
  return "Invalid phone number"
end


def clean_phone_number(number)
  filtered_number = filter_number(number)
  return fix_filtered_number(filtered_number)
end


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end


def format_datetime(datetime)
  Time.strptime(datetime, "%m/%d/%y %H:%M")
end


def compute_peak_hour(datetime)
  formatted_datetime = format_datetime(datetime)
  hour = formatted_datetime.hour
  @hours[hour] += 1
end


def compute_peak_day(datetime)
  formatted_datetime = format_datetime(datetime)
  day = formatted_datetime.wday
  @days[day] += 1
end


def get_peak_hour
  max_with_index = @hours.each_with_index.max
  max_with_index[1]
end


def get_peak_day_of_week
  max_with_index = @days.each_with_index.max
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
  phone_num = clean_phone_number(row[:homephone])
  compute_peak_hour(row[:regdate])
  compute_peak_day(row[:regdate])

  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

contents.close

puts "Peak registration hour is #{get_peak_hour} o'clock."
puts "Peak registration day of the week is #{get_peak_day_of_week}."
