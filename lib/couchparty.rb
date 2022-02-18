require "bundler/setup"
Bundler.require(:default)

require 'httpx'
require 'mime/types'

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
    def server(url:, name: nil, password: nil , logger: nil)
      CouchParty::Server.new(url: url, name: name, password: password ,logger: logger)
    end

    def database(url: , db:, name: nil, password: nil , logger: nil)
      server = CouchParty::Server.new(url: url, name: name, password: password ,logger: logger)
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
