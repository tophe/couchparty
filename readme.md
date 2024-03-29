# couchparty : modern ruby Couchdb driver

CouchParty is a modern ruby driver for couchdb. It target ruby-3+ and couchdb v3+. It is greatly inspired by couchRest, but it is
simpler. It use ruby HTTPX, so every connection use http keepalive, it can easily support http/2 thank's HTTPX.
The api is almost compatible with couchRest, but it is not a dropping, you have to adapt some code.
## what's new
- use net/http
- support for partitioned databases
- support for mango query
- support ruby 3.1
- use cookie authent, and keepalived connection.
- check consistancy on attachements fetching

## what missing
Attachments in base64 aren't supported yet. You can't use options attachments with all methods that support it.

# logging
```ruby
logger = Logger.new(STDOUT)
logger.level = Logger::INFO
server    = CouchParty.server(url: COUCHHOST, logger: logger)
# log to STDOUT
```

# install
gem install couchparty
or
gem 'couchparty', git: 'https://github.com/tophe/couchparty', branch: 'main'


# usage
```ruby
require 'couchparty'

server = CouchParty.server()           # assumes localhost by default!
server = CouchParty.server(url: 'http://server:5984', name: name, password: password)           # cookie authent (more performant than basic auth)
server = CouchParty.server(url: 'http://name:password@server:5984')           # basic http auth

db = server.db('testdb')  # select a database

# direct db, use server auth
db = CouchParty.db(url: 'http://server:5984', name: name, password: password)

# couchRest compatible mode use cookie auth
db = CouchParty.database('http://name:password@server:5984/db')

partition = db.partition('partid')  # get a partition from the database

body = {"selector" => {"content" => {"$eq" => 'hello'}}}
query = partition.find(body)
# or find an db
query = db.find(body)

# all_docs
query = partition.all_docs(options)
query = db.all_docs(options)


# Save a document, with ID
db.save_doc({'_id' => 'doc', 'name' => 'test', 'date' => Date.current})

# Fetch doc
doc = db.get('doc')


# Delete
db.delete_doc(doc)
or 
doc.delete

# attachment
doc.put_attachment('moon', 'file.jpg')
attachment = doc.fetch_attachment('moon')
attachment.save('my_file')

# or without loading doc
db.save_attachment({_id: 27}, 'moon', file: my_file)

# from stream
db.save_attachment({_id: 27}, 'moon', stream: my_stream, content_type: 'text/plain')

# present
db.present_attachment(27, 'moon')

# no consistency / presence check !
db.fetch_attachment(docid, name, options: {rev: 'cx'})

# more example in the spec
```

# unimplemented call
it is possible to use the driver for calling a non implemented function.
ex: _change
```ruby
db = server.db('testdb')
changes = db.server.process_query(method: :get, uri: db.uri + '_changes', options: {style: 'all_docs'})
# or if you need status code 
status, changeds = process_query_with_status(method: :get, uri: db.uri + '_changes', options: {style: 'all_docs'})

=> 
{"results"=>[{"seq"=>"1-g1AAAABteJzLYWBgYMpgTmHgzcvPy09JdcjLz8gvLskBCScyJNX___8_K5EBh4I8FiDJ0ACk_oPUZTAnMuYCBdgNEw3MzI3N0fVkAQAMdCGm", "id"=>"1:bob", "changes"=>[{"rev"=>"1-bd85d49a88be80885568472bf2028da4"}]}, {"seq"=>"2-g1AAAACLeJzLYWBgYMpgTmHgzcvPy09JdcjLz8gvLskBCScyJNX___8_K4M5kTEXKMBukmZubmRoiK4Yh_Y8FiDJ0ACk_qOYYphoYGZubI6uJwsAK5Ep8Q", "id"=>"_design/45a1aa79a2594ba91e892430be0f395d390e9da7", "changes"=>[{"rev"=>"1-7d490c0c313b63ce054bcf65bdb5f8bc"}]}], "last_seq"=>"2-g1AAAACLeJzLYWBgYMpgTmHgzcvPy09JdcjLz8gvLskBCScyJNX___8_K4M5kTEXKMBukmZubmRoiK4Yh_Y8FiDJ0ACk_qOYYphoYGZubI6uJwsAK5Ep8Q", "pending"=>0}
```

# specs

The test need to start a local couchdb.
you can use docker/docker-compose.yml. You can create docker/.env with
COUCHDB_USER=myuser
COUCHDB_PASSWORD=mypass

You can now docker-compose up -d, eventualy you can configure the db in single mode via http://localhost:5984/_utils, but this is not necessary.
Eventually use ENV['COUCHHOST'] to set an alternative server.
the test create and delete 2 databases.

run
```
bundle install
rspec
or
COUCHPARTY_DEBUG=1 rspec
```

# Contact
bug, suggestion can be post on github repo.

# problem
gzip support, doesn't work, it need to write file to gzip data, because of the ruby string support.
```ruby
content = {"_id"=>"bob", "content"=>"truc"}
3.1.0 :074 > sjson = content.to_json
=> "{\"_id\":\"bob\",\"content\":\"truc\"}"
sio = StringIO.new
sio.binmode # don't help
sio.write sjson
sio.string
=> "{\"_id\":\"bob\",\"content\":\"truc\"}"
```
sio.string should be  => "{"_id":"bob","content":"truc"}" to be valid couch json.
so we need to do
```ruby
      if content && @gzip

        # write content to a file need to use tempfile
        File.open('json.json','w') { |io| io.puts(json.to_json)}

        # read content in bin mode
        content_bin= File.new('json.json','rb').read
        sio = StringIO.new
        sio.binmode
        @gziper = Zlib::GzipWriter.new(sio)
        @gziper.write content_bin
        content = @gziper.close.string
      end
```
content must be serialize and read from a real file, because a simple @gziper.write content.to_json don't work
without workaround, I have disable gzip support.


# inspiration
https://github.com/couchrest/couchrest  
https://docs.couchdb.org/en/stable/  
https://hexdocs.pm/couchdb/  
