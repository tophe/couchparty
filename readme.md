# couchparty : Couchdb ruby driver

CouchParty is a thin ruby driver for couchdb. It target ruby-3+ and couchdb v3+. It is greatly inspired by couchRest, but it is
simpler. It use ruby HTTPX, so every connection use http keepalive, it can easily support http/2 thank's HTTPX.
The api is almost compatible with couchRest, but it is not a dropping, you have to adapt some code.
## what's new
- use HTTPX
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
gem 'couchparty', git: 'https://github.com/tophe/couchparty'

# usage
```ruby
server = CouchParty.new()           # assumes localhost by default!
server = CouchParty.new(url: 'http://server:5984', name: name, password: password)           # cookie authent
server = CouchParty.new(url: 'name:password@http://server:5984')           # basic http auth
db = server.db('testdb')  # select a database
partition = db.partition('partid')  # get a partition from the database
body = {"selector" => {"content" => {"$eq" => 'hello'}}}
query = part.find(body)
or
query = db.find(body)

# Save a document, with ID
db.save_doc('_id' => 'doc', 'name' => 'test', 'date' => Date.current)

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
you can use docker/docker-compose.yml. Start by create docker/.env with
COUCHDB_USER=myuser
COUCHDB_PASSWORD=mypass
You can now docker-compose up -d and configure the db in single mode via http://localhost:5984/_utils.
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




# inspiration
https://github.com/cobot/couchrest
https://gitlab.com/honeyryderchuck/httpx
https://docs.couchdb.org/en/stable/
https://hexdocs.pm/couchdb/
