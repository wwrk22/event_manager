require 'csv'
require 'google/apis/civicinfo_v2'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end


def collect_legislator_names(legislators)
  legislators.map(&:name).join(", ")
end


def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    return collect_legislator_names(legislators.officials)
  rescue Google::Apis::ClientError
    return "Failed to find representative for given inforamation. "\
    "Find your representative at "\
    "www.commoncause.org/take-action/find-elected-officials"
  end
end


template_letter = File.read('./form_letter.html')

puts "Event Manager initialized"

contents = CSV.open(
  './event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  personal_letter = template_letter.gsub('FIRST_NAME', name)
  personal_letter.gsub!('LEGISLATORS', legislators)
  puts personal_letter
end

contents.close
