require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phonenumber(phonenumber)
  numbers = phonenumber.scan(/\d/)

  if numbers.length == 10
    numbers.join('')
  elsif numbers.length == 11 && numbers[0] == '1'
    numbers[1..9].join('')
  else
    'No valid phone number'
  end
end

def find_legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thankyou_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks #{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def registrations_on_day(date_hash, num)
  tally_of_days = date_hash.tally
  most_days = tally_of_days.max(num) { |pair1, pair2| pair1[1] <=> pair2[1] }

  most_days.each do |day, number|
    puts "#{number} people registered on a #{day}"
  end
end

def registrations_at_hours(time_hash, num)
  tally_of_hours = time_hash.tally
  most_hours = tally_of_hours.max(num) { |pair1, pair2| pair1[1] <=> pair2[1] }

  most_hours.each do |hour, number|
    puts "#{number} people registered between #{hour}:00 and #{hour + 1 == 24 ? '00' : hour + 1}:00"
  end
end

puts 'Event Manager intialized!'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

reg_dates = []
reg_times = []

contents = CSV.open('event_attendees.csv',
                    headers: true,
                    header_converters: :symbol)

contents.each do |row|
  id = row[0]

  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = find_legislators_by_zipcode(zipcode)

  phonenumber = clean_phonenumber(row[:homephone])

  date = row[:regdate].split(' ')
  reg_dates.push(Date.strptime(date[0], '%D').strftime('%A'))
  reg_times.push(Time.strptime(date[1], '%k:%M').hour)

  puts "#{name}: #{phonenumber}, registered: #{date}"

  form_letter = erb_template.result(binding)

  save_thankyou_letter(id, form_letter)
end

registrations_on_day(reg_dates, 3)
registrations_at_hours(reg_times, 3)
