require "bundler/setup"
Bundler.require(:default)

# require 'httpx'
require 'http-cookie'
require 'mime/types'
require 'net/http'
require 'zlib'

require 'couch_party/version'
require 'couch_party/server'
require 'couch_party/database'
require 'couch_party/document'
require 'couch_party/partition'
require 'couch_party/design'
require 'couch_party/attachment'
require 'couch_party/couch_error'




module CouchParty
  puts "Relax couchparty v#{VERSION} loaded!"
  class << self


    # Instantiate a new Server object
    def server(url:, name: nil, password: nil , logger: nil, gzip: false, proxy_host: nil, proxy_port: nil, read_timeout: 60)
      CouchParty::Server.new(url: url, name: name, password: password ,logger: logger, gzip: gzip, proxy_host: proxy_host, proxy_port: proxy_port, read_timeout: read_timeout)
    end

    # couchrest compatibility
    def database(url, logger: nil)
      uri = URI(url)


      db = uri.path[1..-1]
      raise "Error url, database not specified" if db.empty?
      uri.path = ''
      name = uri.user
      uri.user = nil
      password = uri.password
      uri.password = nil
      server_url =  uri.to_s


      db(url: server_url, db: db, name: name, password: password, logger: logger)
    end

    def db(url: , db:, name: nil, password: nil , logger: nil, gzip: false, proxy_host: nil, proxy_port: nil, read_timeout: 60)
      server = CouchParty::Server.new(url: url, name: name, password: password ,logger: logger, gzip: gzip, proxy_host: proxy_host, proxy_port: proxy_port, read_timeout: read_timeout)
      server.db(db: db)
    end

    def get(url:)

    end

    def post

    end
    def head

    end
    def put

    end


  end

end
