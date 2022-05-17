
module CouchParty


  class CouchError < StandardError

    attr_reader :status
    # doc, change ruby symbol to string
    def initialize(httperr)
      @status = httperr.code
      super(httperr.message)

    end


  end
end
