require File.expand_path("../../spec_helper", __FILE__)

module CouchParty
  describe CouchParty::Document do
    let :server do
      CouchParty.server(url: COUCHHOST)
    end
    before :all do
      TEST_SERVER.delete(db: TESTDB)
      TEST_SERVER.create(db: TESTDB)
      doc = { _id: 'bob', content: 'truc'}
      TEST_SERVER.db(db: TESTDB).save_doc(doc)

    end
    describe "#initialize" do
      it "should prepare frozen URI object" do
        expect(server.uri).to be_a(URI)
        expect(server.uri).to be_frozen
        expect(server.uri.to_s).to eql(COUCHHOST)
      end

      it "should clean URI" do
        server = CouchParty.server(url: COUCHHOST + "/some/path?q=1#fragment")
        expect(server.uri.to_s).to eql(COUCHHOST)
      end

      # it "should set default uuid batch count" do
      #   expect(server.uuid_batch_count).to eql(1000)
      # end

      # it "should set uuid batch count" do
      #   server = CouchParty::Server.new(mock_url, 1234)
      #   expect(server.uuid_batch_count).to eql(1234)
      #   server = CouchParty::Server.new(mock_url, :uuid_batch_count => 1235)
      #   expect(server.uuid_batch_count).to eql(1235)
      # end

      # it "should set connection options" do
      #   server = CouchParty::Server.new(mock_url)
      #   expect(server.connection_options).to be_empty
      #   server = CouchParty::Server.new(mock_url, :persistent => false)
      #   expect(server.connection_options[:persistent]).to be_false
      # end
    end

    describe :logger do
      it "should use logger" do
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
        server    = CouchParty.server(url: COUCHHOST, logger: logger)

        server.logger.info('test')
        server.all_dbs
      end

    end

    describe :databases do

      it "should provide list of databases name" do
        expect(server.all_dbs).to include(TESTDB)
      end
      it "should provide info on server" do
        expect(server.info.has_key?('version')).to be_truthy
      end
    end

    describe :auth do
      it "should  auth user" do
        uri = URI(COUCHHOST)
        nuri = uri.scheme + '://' + uri.host + ':' + uri.port.to_s + '/' + uri.path
        server = CouchParty.server(url: nuri, name: uri.user, password: uri.password)
        expect(server.all_dbs.class).to eq(Array)
      end

      it "should reaut user if cookie timed out" do
        uri = URI(COUCHHOST)
        nuri = uri.scheme + '://' + uri.host + ':' + uri.port.to_s + '/' + uri.path
        server = CouchParty.server(url: nuri, name: uri.user, password: uri.password)
        expect(server.all_dbs.class).to eq(Array)
        server.clear_auth
        expect(server.all_dbs.class).to eq(Array)
      end

    end

    after :all do
      # puts "after all"

      TEST_SERVER.delete(db: TESTDB)
    end
  end
end
