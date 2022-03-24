require File.expand_path("../../spec_helper", __FILE__)
module CouchParty
  describe CouchParty::Partition do

    before :all do
      TEST_SERVER.delete(db: TESTDB_PART)
      TEST_SERVER.create(db: TESTDB_PART, options: {partitioned: true})
      doc = { _id: '1:bob', content: 'truc'}
      TEST_SERVER.db(db: TESTDB_PART).save_doc(doc)

    end

    let :the_doc do
      { _id: '1:bob', content: 'truc'}
    end

    let :server do
      TEST_SERVER
    end

    let :db do
      TEST_SERVER.db(db: TESTDB_PART)
    end

    let :part do
      TEST_SERVER.db(db: TESTDB_PART).partition(1)
    end

    let :docid do
      '1:bob'
    end

    describe :init do
      it 'should return partition' do
        part = db.partition(1)
        expect(part.class).to eq(CouchParty::Partition)


        # expect(doc.respond_to?(:to_json)).to be_truthy
        # expect(doc.to_json).to eq(the_doc.to_json)
      end
    end

    describe :method do
      it "should provide all docs" do
        docs = part.all_docs
        expect(docs.has_key?('rows')).to be_truthy
        expect(docs["total_rows"]).to eq(1)
      end

      it "should find via mango docs" do
        json = {"selector" => {"content" => {"$eq" => the_doc['truc']}}}
        query = part.find(json)
        expect(query.has_key?('docs')).to be_truthy
      end

      it "should find via mango docs with index" do
        TEST_SERVER.db(db: TESTDB_PART).save_doc( { _id: '1:mg', content: 'find_mango'})

        index =  '{
          "index": {
            "fields": ["content"]
          },
          "name" : "foo-index",
          "type" : "json",
          "partitioned" : true
        }'

        index = JSON.parse(index)
        ret =  db.create_index(index)
        expect(ret["result"]).to eq('created')

        json = {"selector" => {"content" => {"$eq" => 'find_mango'}}}
        query = part.find(json)
        expect(query['docs'].size).to eq(1)
        doc = query['docs'].first

        expect(doc.class).to eq(Document)
        expect(doc.send(:_id)).to eq('1:mg')
        del = doc.delete
        expect(del['ok']).to be_truthy

      end



    end


    after :all do
      # puts "before all"
      TEST_SERVER.delete(db: TESTDB)
    end

  end
end
