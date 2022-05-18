require "bundler/setup"
require "rubygems"
require "rspec"
require "webmock/rspec"



require File.join(File.dirname(__FILE__), '..','lib','couchparty')
# check the following file to see how to use the spec'd features.

unless defined?(FIXTURE_PATH)
  FIXTURE_PATH = File.join(File.dirname(__FILE__), '/fixtures')
  SCRATCH_PATH = File.join(File.dirname(__FILE__), '/tmp')

  AUTH = {'COUCHDB_USER' => 'admin', 'COUCHDB_PASSWORD' => 'mysecretpassword'}
  # read authent attributes from docker/.env
  if File.exist?('./docker/.env')
    File.open('./docker/.env').each do |line|
      line.strip!
      next if line.empty?
      att, value = line.split('=')
      AUTH[att] = value
    end
  end

  COUCHHOST = ENV['COUCHHOST'] || "http://#{AUTH["COUCHDB_USER"]}:#{AUTH["COUCHDB_PASSWORD"]}@localhost:5984"
  TESTDB    = 'couchparty-test'
  TESTDB_PART    = 'couchparty-test-part'
  REPLICATIONDB = 'couchparty-test-replication'
  # TEST_SERVER    = CouchParty.server(url: COUCHHOST, gzip: true)
  TEST_SERVER    = CouchParty.server(url: COUCHHOST)

end

# Allows us to hack Specific request responses
WebMock.disable_net_connect!(:allow_localhost => true)

# def reset_test_db!
#   DB.recreate! rescue nil
#   DB
# end

RSpec.configure do |config|
  # config.before(:all) do
  #   reset_test_db!
  # end
  #
  # config.after(:all) do
  #   cr = TEST_SERVER
  #   test_dbs = cr.databases.select { |db| db =~ /^#{TESTDB}/ }
  #   test_dbs.each do |db|
  #     cr.database(db).delete! rescue nil
  #   end
  # end
end

# Check if lucene server is running on port 5985 (not 5984)
# def couchdb_lucene_available?
#   url = URI "http://localhost:5985/"
#   req = Net::HTTP::Get.new(url.path)
#   Net::HTTP.new(url.host, url.port).start { |http| http.request(req) }
#   true
# rescue Exception
#   false
# end
