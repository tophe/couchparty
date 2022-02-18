require 'couch_party/finder'

module CouchParty
  class Partition
    include Finder

    attr_reader :partition, :db

    def initialize(partition, db: )
      @partition = partition.to_s
      @db = db
      @server = @db.server
    end

    def uri
      @db.uri.to_s + '_partition/' + partition + '/'
    end


  end
end
