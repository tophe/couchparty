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


  # after :each do
  #   puts "after each"
  # end

  # after :all do
  #   # puts "after all"
  #
  #   TEST_SERVER.delete(db: TESTDB)
  # end

  describe :bulk do
    it "should get_bulk" do
      db.save_doc({_id: 'bla', content: 'truc'})

      docs = [{id: 'bob'},{id: 'bla'}]
      finded_docs = db.bulk_get(docs)

      to_update = []
      finded_docs["results"].each do |res|
        res["docs"].each do |doc|
          to_update << doc["ok"]
          expect(doc.has_key?("ok")).to be_truthy
        end
      end

      to_update.each { |doc| doc["update"]="update" }

      res =  db.bulk_docs(to_update)
      res.each do |doc|
        expect(doc["ok"]).to be_truthy
      end

    end

  end
end
end
