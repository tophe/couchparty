require File.expand_path("../../spec_helper", __FILE__)
module CouchParty
describe CouchParty::Design do



  let :the_doc do
    {language: 'js'}
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

  describe :init do
    it 'should serialize to json' do
      design = Design.new(docid, the_doc)

      expect(design.respond_to?(:to_json)).to be_truthy
      expect(design._id).to eq('_design/' + docid)

    end
  end

  describe :nopartition do
    before :all do
      TEST_SERVER.delete(db: TESTDB)
      TEST_SERVER.create(db: TESTDB)
      doc = { _id: 'bob', content: 'truc'}
      TEST_SERVER.db(db: TESTDB).save_doc(doc)

    end

      it "should save" do
        design = db.get(docid)
        resp = design.save
        expect(resp["ok"]).to eq(true)
      end

      it "should update " do
        design = db.get(docid)
        design.doc["autoupdate"] = false
        resp = design.save
        expect(resp["ok"]).to eq(true)
      end
      it "should view " do
        ddoc = 'bob'
        design = {
          "views"=>
            {"by_dt"=>
               {"map"=>
                  "function(doc)\n{\n  emit(doc._id, 1);  \n}"}},
          "language"=>"javascript"
          }

        resp = db.save_design(ddoc, design)

        design = db.get_design('bob')

        expect(design.class).to eq(Design)

        resp = design.view('by_dt')
        expect(resp["total_rows"]).to eq(1)

      end
      it "should delete" do
        design = db.get(docid)
        resp = design.delete
        expect(resp["ok"]).to eq(true)

      end
  end

  describe :partition do
    before :all do
      TEST_SERVER.delete(db: TESTDB_PART)
      TEST_SERVER.create(db: TESTDB_PART, options: {partitioned: true})
      doc = { _id: '1:bob', content: 'truc'}
      TEST_SERVER.db(db: TESTDB_PART).save_doc(doc)

    end
    let :db do
      TEST_SERVER.db(db: TESTDB_PART)
    end

    it "should create design doc" do

      ddoc = 'bob'
      design = {
        "views"=>
          {"by_dt"=>
             {"map"=>
                "function(doc)\n{\n  emit(doc._id, 1);  \n}"}},
        "language"=>"javascript",
        "options"=>{"partitioned"=>true}}

      resp = db.save_design(ddoc, design)

      expect(resp["ok"]).to eq(true)

    end

    it "should view design doc" do
      design = db.get_design('bob')
      expect(design.class).to eq(Design)

      expect { design.view('by_dt') }.to raise_error(RuntimeError)

      resp = design.view('by_dt', partition: 1)
      expect(resp["total_rows"]).to eq(1)
      expect(resp["rows"].first['key']).to eq('1:bob')
    end

  end

  after :all do
    # puts "before all"
    TEST_SERVER.delete(db: TESTDB)
  end

end
end
