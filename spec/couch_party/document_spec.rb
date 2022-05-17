require File.expand_path("../../spec_helper", __FILE__)
require 'digest'

module CouchParty
describe CouchParty::Document do

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

  describe :init do
    it 'should serialize to json' do
      doc = Document.new(the_doc)
      expect(doc.respond_to?(:to_json)).to be_truthy
      expect(doc.to_json).to eq(the_doc.to_json)
    end
  end

  describe :methods do

      it "should save" do
        doc = db.get(docid)
        doc.doc['content'] = 'bla'
        doc.save

        doc = db.get(docid)
        expect(doc.doc['content']).to eq('bla')
      end
      it "should delete" do
        doc = db.get(docid)
        del = doc.delete
        expect(del.has_key?('ok')).to be_truthy
        TEST_SERVER.db(db: TESTDB).save_doc(the_doc)

      end
      it 'should update' do

        doc = db.get(docid)
        doc.update_doc({content: 'bla', other: 'other'})

        expect(doc.doc.keys.include?('other')).to be_truthy
        expect(doc.doc['content']).to eq('bla')
      end

  end

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

  describe :attachements do

    it "should save attachement" do
      doc = db.get(docid)
      moon = FIXTURE_PATH + '/moon.jpg'
      mime = MIME::Types.type_for( moon)

      expect(doc.class).to eq(CouchParty::Document)
      doc.put_attachment('moon', moon)

      #doc = db.get(docid)
      expect(doc._attachments.size).to eq(1)

      expect(doc._attachments['moon']['content_type']).to eq('image/jpeg')
    end

    it "should delete an attachement" do
      doc = db.get(docid)
      doc.delete_attachment('moon')
      expect(doc._attachments.size).to eq(0)
    end

    it "should not fetch an attachment missing" do
      doc = db.get(docid)
      expect { doc.fetch_attachment('bob') }.to raise_error(RuntimeError)
    end

    it "should fetch an attachement" do
      doc = db.get(docid)
      moon = FIXTURE_PATH + '/moon.jpg'
      doc.put_attachment('moon', moon)

      moon_fetch = FIXTURE_PATH + '/moon_fetch.jpg'
      attachment = doc.fetch_attachment('moon')
      expect(attachment.class).to eq(CouchParty::Attachment)

      File.open(moon_fetch,'w') { |io| io.write(attachment.content)}
      expect(File.size(moon_fetch)).to eq(File.size(moon))

      File.delete(moon_fetch) if File.exist?(moon_fetch)
      attachment.save(moon_fetch)
      expect(File.size(moon_fetch)).to eq(File.size(moon))

      digest = 'md5-' + Digest::MD5.base64digest(File.open(moon_fetch).read)
      att = doc._attachments['moon']
      expect(att['length']).to eq(File.size(moon))
      expect(att['digest']).to eq(digest)


    end
  end

  after :all do
    # puts "before all"
    TEST_SERVER.delete(db: TESTDB)
  end

end
end
