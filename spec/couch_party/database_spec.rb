require File.expand_path("../../spec_helper", __FILE__)
module CouchParty
describe CouchParty::Database do

  before :all do
    TEST_SERVER.delete(db: TESTDB)
    TEST_SERVER.create(db: TESTDB)
    doc = { _id: 'bob', content: 'truc'}
    TEST_SERVER.db(db: TESTDB).save_doc(doc)

  end

  let :the_doc do
    { _id: 'bob', content: 'truc'}
  end

  let :server do
    TEST_SERVER
  end

  let :db do
    TEST_SERVER.db(db: TESTDB)
  end

  let :docid do
    'bob'
  end

  describe "#initialize" do


    it "should create db" do
      expect(db.server.class).to eq(CouchParty::Server)
      expect(db.server.uri.to_s).to eq(COUCHHOST)
      expect(db.db).to eq(TESTDB)
    end


  end




  describe :methods do

    it "should provide info on server" do
      expect(db.info.has_key?('db_name')).to be_truthy
    end

    it "should provide all docs" do
      expect(db.all_docs.has_key?('rows')).to be_truthy
    end

    it "should find via mango docs" do
      json = {"selector" => {"idcustomerfollow" => {"$eq" => 368636735}}}
      # p db.find(body: body)
      expect(db.find(json).has_key?('docs')).to be_truthy
    end


  end

  describe :docs do
    it "should return doc if exist" do

      doc = db.get(docid)

      expect(doc.class).to eq(CouchParty::Document)
      expect(doc._id).to eq(docid)
      expect(doc._rev.nil?).to be_falsy
      expect(doc.doc['content']).to eq(the_doc[:content])
    end

    it "should update doc if exist" do

      doc = db.get(docid)
      doc.doc['content'] = 'bla'
      db.save_doc(doc)

      doc = db.get(docid)
      expect(doc.doc['content']).to eq('bla')
    end


    it "should delete doc if exist" do
      doc = db.get(docid)
      del = db.delete_doc(doc)
      expect(del.has_key?('ok')).to be_truthy
      TEST_SERVER.db(db: TESTDB).save_doc(the_doc)

    end

    it "should return exception if option not in get" do
      expect { db.get('ba', options: {'bob': true}) }.to raise_error(RuntimeError)
    end

    it "should allow rev in get" do
      doc = db.get(docid)
      doc = db.get(docid, options: {rev: doc._rev})
    end
    it "should allow revs_info in get" do
      doc = db.get(docid, options: {revs_info: 3})
      expect(doc._revs_info.size > 0).to be_truthy
    end
    it "should allow revs in get" do
      doc = db.get(docid, options: {revs: true})
      expect(doc._revisions.size > 0).to be_truthy
    end

    it "should return exception if doc doesn't exist" do
      expect { db.get('ba') }.to raise_error(CouchError)
    end


    it "should return true if  doc exist" do
      doc = db.exist?(docid)
      expect(doc).to be_truthy
    end

    it "should return false if  doc exist" do
      doc = db.exist?('ba')
      expect(doc).to be_falsy
    end

    it "should return info" do
      info = db.info
      expect(info['db_name']).to eq(TESTDB)
    end


  end



  describe :index do
    it "should list indexes" do
      indexes = db.index
      expect(indexes.has_key?("indexes")).to be_truthy
    end
    it "should create an index" do
      index = '
      {
        "index": {
          "fields": ["foo"]
        },
        "name" : "foo-index",
        "type" : "json"
      }'
      index = JSON.parse(index)
      ret =  db.create_index(index)

      expect(ret["result"]).to eq('created')
    end
    it "should delete index" do
      indexes = db.index
      indexes["indexes"].each do |index|
        if index['name'] == 'foo-index'

          ret = db.delete_index(index['ddoc'], index['name'])
          expect(ret["ok"]).to eq(true)
        end
      end
    end
  end


    describe :design do

      it "should create  and delete design doc" do

        ddoc = 'bob'
        design = {
          "views"=>
            {"by_dt"=>
               {"map"=>
                  "function(doc)\n{\n  emit(doc._id, 1);  \n}"}},
          "language"=>"javascript",
          "options"=>{"partitioned"=>false}}

        resp = db.save_design(ddoc, design)

        expect(resp["ok"]).to eq(true)

        design = db.get_design('bob')
        resp = db.delete_design(design)
        expect(resp["ok"]).to eq(true)

      end

      it "should create and return a design doc" do
        ddoc = 'bob'
        design = {
          "views"=>
            {"by_dt"=>
               {"map"=>
                  "function(doc)\n{\n  emit(doc._id, 1);  \n}"}},
          "language"=>"javascript",
          "options"=>{"partitioned"=>false}}

        resp = db.save_design(ddoc, design)

        design = db.get_design('bob')
        expect(design.class).to eq(Design)
        expect(design._id).to eq('_design/bob')
      end


    end



  describe :nomethod do
    it "should return changes" do
      changes = TEST_SERVER.process_query(method: :get, uri: db.uri + '_changes', options: {style: 'all_docs'})
      expect(changes.has_key?('results')).to be_truthy

    end
  end

  describe :attachment do
    it "should fetch nil if attachment missing" do
      att = db.fetch_attachment(docid, 'moon')
      expect(att).to eq(nil)
    end
    it "should raise error if attachment missing" do
      expect { db.fetch_attachment!(docid, 'moon') }.to raise_error(CouchError)
    end

    it "should raise error 404 if attachment missing" do
      begin
        db.fetch_attachment!(docid, 'moon')
      rescue CouchError => e
        expect(e.status).to eq(404)
      end

    end
  end
  # after :each do
  #   puts "after each"
  # end

  after :all do
    # puts "after all"

    TEST_SERVER.delete(db: TESTDB)
  end
end
end
