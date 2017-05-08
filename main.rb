require 'net/http'
require 'uri'
require 'json'
require 'time'

# based on time when github is found
OVERALL_START_TIME = Time.utc(2008,1,1)
OVERALL_END_TIME = Time.now.utc + 60*60
LOCATION = 'singapore'
API_SEARCH_LIMIT = 1000 # max limit of results for each search
API_PAGE_LIMIT = 100 # max limit of results per page
BASE_URL = "https://api.github.com/search/users"
ACCESS_TOKEN = ARGV[0]

$sg_users = []

def get_json_from_github(uri)
  response = nil

  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new uri
    response = http.request request
    puts "Get response from #{uri}"
  end

  # deal with github rate limiting
  while response.code != '200' && response['x-ratelimit-remaining'] == '0'
    # sleep until rate limit is lifted
    puts "Rate limited, wait until #{Time.at(response['x-ratelimit-reset'].to_i)} for reset"
    sleep (response['x-ratelimit-reset'].to_i - Time.now.utc.to_i)

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new uri
      response = http.request request
      puts "Get response from #{uri}"
    end
  end

  JSON.parse(response.body)
end

# use github search api to search users who joined within a time range
def search_within_range(start_time, end_time)
  url = "#{BASE_URL}\?q\=location:#{LOCATION}+created:#{start_time.iso8601}..#{end_time.iso8601}"
  url = url + "&access_token=#{ACCESS_TOKEN}" if ACCESS_TOKEN # speed up if possible
  uri = URI(url)
  json = get_json_from_github(uri)

  # if total_count is larger than limit, do spliting
  if json['total_count'].to_i > API_SEARCH_LIMIT
    middle_time = (start_time.to_i + end_time.to_i)/2
    # binary search first part
    search_within_range(start_time, Time.at(middle_time).utc)
    # binary search second part
    search_within_range(Time.at(middle_time).utc, end_time)
  else
    # page through results
    end_page = json['total_count'].to_i/API_PAGE_LIMIT + 1

    (1..end_page).each do |page|
      url = "#{BASE_URL}\?q\=location:#{LOCATION}+created:#{start_time.iso8601}..#{end_time.iso8601}&page=#{page}&per_page=#{API_PAGE_LIMIT}"
      url = url + "&access_token=#{ACCESS_TOKEN}" if ACCESS_TOKEN
      uri = URI(url)
      json = get_json_from_github(uri)
      $sg_users.concat(json['items'])
      puts "Added #{json['items'].size} users into list"
    end
  end
end

search_within_range(OVERALL_START_TIME, OVERALL_END_TIME)

puts "There are toally #{$sg_users.size} users in Singapore"
puts "Open users.json for records"

File.open("./users.json","w+") do |f|
  f.write(JSON.pretty_generate($sg_users))
end
