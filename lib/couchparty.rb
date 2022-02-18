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

puts 'Relax couchparty loaded!'


module CouchParty

  class << self


    # Instantiate a new Server object
    def server(url:, name: nil, password: nil , logger: nil)
      CouchParty::Server.new(url: url, name: name, password: password ,logger: logger)
    end

    def database(url: ,db: )
      server = CouchParty::Server.new(url: url, db: db)
      CouchParty.Database.new(server: server, db: db)
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
