require 'sinatra'
require 'twilio-ruby'
require 'net/http'
require 'uri'
require 'json'
require 'bitly'

account_sid = 'AC6518dab40e58470c70c0e7863fc091aa'
auth_token = ENV['TWIL_TOKEN']

nyt_key = ENV['NYT_KEY']

bitly_username = 'hatboysam'
bitly_api_key = ENV['BITLY_KEY']

get '/' do
	"Hello, HackNY"
end

get '/text' do
  params[:Body] ||= 'release'

  # Build the query
  base = "http://api.nytimes.com/svc/search/v1/article?format=json&query="
  query = params[:Body]
  tail = "&begin_date=19810101&end_date=20130101&rank=closest&api-key=#{nyt_key}"

  # NYTimes API
  uri = URI.parse(base + query + tail)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)

  # Bitly API
  Bitly.use_api_version_3
  bitly = Bitly.new(bitly_username, bitly_api_key)

  message = "Something old-timey!"
  if response.code == "200"
    result = JSON.parse(response.body)
    first_result = result['results'].first
    short_link = bitly.shorten(first_result['url']).short_url
    message = short_link + ' - ' + first_result['title'] + " - " + first_result['body']
    message.strip!
    # Ellipses, for style
    message = message + '...'
  end

  # Twilio
  @client = Twilio::REST::Client.new account_sid, auth_token
  twiml = Twilio::TwiML::Response.new do |r|
    r.Message message
  end
  twiml.text
end