require File.expand_path("../../spec_helper", __FILE__)
module CouchParty
describe CouchParty::Database do



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
end
end
