require 'net/http'
require 'json'
require 'http-cookie'

def request_factory(type, url)
  case type
  when :get
    request = Net::HTTP::Get.new url
  when :post
    request = Net::HTTP::Post.new url
  end

  @request_headers.each do |header, value|
    request[header] = value
  end

  request['Cookie'] = HTTP::Cookie.cookie_value(@jar.cookies(url))

  request
end

uri = URI('http://store:5984/customerfollow')

ENV["http_proxy"] = "http://localhost:8888"

# keep alive ok
# Net::HTTP.start(uri.host, uri.port) do |http|
#   request = Net::HTTP::Get.new uri
#
#   response = http.request request # Net::HTTPResponse object
#   p response.body
#   response = http.request request # Net::HTTPResponse object
#   p response.body
# end
@jar = HTTP::CookieJar.new

@request_headers =   {'content-type' => 'application/json',
                      'Accept' => 'application/json',
                       'User-Agent' => "CouchParty/1.2"}
@auth_h = {name: 'admin', password:  'mokija' }

session = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https')


# auth
request = request_factory(:post, uri+"/_session")
response = session.request(request, @auth_h.to_json)
p response.body
response.get_fields('Set-Cookie').each do |value|
  @jar.parse(value, request.uri)
end



request = request_factory(:get,  uri)
#request.basic_auth 'admin', 'mokija'

response = session.request(request)

p response.body

response.each_header.each do |key, value|
  p key, value
  # jar.parse(value, req.uri)
end

p response["Set-Cookie"]
p response.get_fields("connection")

# response = session.request(request)
# p response.body
session.finish
