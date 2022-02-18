
module CouchParty


  class CouchError < StandardError

    attr_reader :status
    # doc, change ruby symbol to string
    def initialize(httperr)
      @status = httperr.status
      super(httperr.message)

    end


  end
end
