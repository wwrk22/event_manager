require 'csv'
require 'google/apis/civicinfo_v2'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end


def collect_legislator_names(legislators)
  legislators.map(&:name)
end

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'


puts "Event Manager initialized"

contents = CSV.open(
  './event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  
  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislator_names = collect_legislator_names(legislators.officials).join(", ")
  rescue Google::Apis::ClientError
    "Failed to find representative for given inforamation. "\
    "Find your representative at "\
    "www.commoncause.org/take-action/find-elected-officials"
  end

  puts "#{name}, #{zipcode}, #{legislator_names}"
end

contents.close
