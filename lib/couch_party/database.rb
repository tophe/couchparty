require 'couch_party/finder'

module CouchParty
  class Database

    include Finder

    attr_reader :server, :db


    def initialize(server: , db: , options: {limit: 25})
      @server = server
      @db = db
      @options = options
    end

    def info
      @server.process_query(method: :get, uri: uri )
    end


    # read database security
    def get_security
      @server.process_query(method: :get, uri: uri + '/_security' )
    end

    # set database security
    # ex:
    # security_hash = {"admins": { "names": [], "roles": ["_admin"] }, "members": { "names": [], "roles": ["_admin"] } }
    def set_security(security_hash: {"admins": { "names": [], "roles": [] }, "members": { "names": [], "roles": [] } })
      @server.process_query(method: :put, uri: uri + '/_security', json: security_hash)
    end




    # fetch docid as a new document, raise error if not found
    def get(docid, options: {})
      allowed_options = %w'rev revs_info revs att_encoding_info atts_since conflicts deleted_conflicts latest local_seq meta open_revs'
      # not supported
      unallowed_options = %w'attachments'

      options ||= {}
      options = JSON.parse(options.to_json)

      options.keys.each do |option|
        raise "Error option : #{option} not allowed in get" unless allowed_options.include?(option)
      end
      # truethy
      %w'revs revs_info'.each do |opt|
        options[opt] = true if options.has_key?(opt)
      end


      doc = @server.process_query(method: :get, uri: uri + docid, options: options)
      return Document.new(doc, db: self)

    end

    # fetch design ddoc
    def get_design(ddoc)

       doc = @server.process_query(method: :get, uri: uri + '_design/' + ddoc)
      return Design.new(ddoc, doc, db: self)

    end

    def save_design(ddoc, design)
      doc =  Design.new(ddoc, design, db: self) unless ddoc.is_a?(Design)
      return @server.process_query(method: :put, uri: uri + '_design/' + ddoc, json: doc)
    end

    # delete design
    # desing is a Design
    def delete_design(design)
      raise "design should be a CouchParty::Design" unless design.is_a?(CouchParty::Design)
      headers = {"If-Match": design._rev}

      return @server.process_query(method: :delete, uri: uri +  design._id , headers: headers)
    end

    #  GET /{db}/{docid}/{attname}
    def  fetch_attachment(docid, attname, options: {})
      allowed_options = %w'rev'

      options ||= {}
      options = JSON.parse(options.to_json)

      options.keys.each do |option|
        raise "Error option : #{option} not allowed in fetch_attachment" unless allowed_options.include?(option)
      end

      status, content = @server.process_query_with_status(method: :get, uri: uri + "/" +docid +  '/' + attname , options: options , no_json: true)

      if status == 200
        attachment = Attachment.new(name, content, nil)
        return attachment
      else
        return nil
      end
    end

    #  GET /{db}/{docid}/{attname}
    def  present_attachment?(docid, attname, options: {})
      allowed_options = %w'rev'

      options ||= {}
      options = JSON.parse(options.to_json)

      options.keys.each do |option|
        raise "Error option : #{option} not allowed in fetch_attachment" unless allowed_options.include?(option)
      end

      status, content = @server.process_query_with_status(method: :head, uri: uri + "/" +docid +  '/' + attname , options: options , no_json: true)

      if status == 200
        return true
      else
        return nil
      end
    end

    #  GET /{db}/{docid}/{attname}
    def  fetch_attachment!(docid, attname, options: {})
      allowed_options = %w'rev'

      options ||= {}
      options = JSON.parse(options.to_json)

      options.keys.each do |option|
        raise "Error option : #{option} not allowed in fetch_attachment" unless allowed_options.include?(option)
      end

      content = @server.process_query(method: :get, uri: uri + "/" +docid +  '/' + attname , options: options , no_json: true)

      attachment = Attachment.new(name, content, nil)

      attachment
    end

    # compact database
    def compact!()
        @server.process_query(method: :post, uri: uri + "/_compact"   )
    end

    def to_s
      uri
    end

    # docs : array of simple {} or Document, in a {} need id and rev if an update is needed.
    # docs = [{"id": "bla"},{"id": "bob", "rev": "4-sfs"}]
    # return couch response
    def bulk_get(docs)
      # allowed_options = %w'new_edits'

      options ||= {}
      options = JSON.parse(options.to_json)

      docs = JSON.parse(docs.to_json)

      # options.keys.each do |option|
      #   raise "Error option : #{option} not allowed in buld_docs" unless allowed_options.include?(option)
      # end
      docs = {'docs' => docs}
      @server.process_query(method: :post, uri: uri + '_bulk_get', options: options, json: docs)

    end

    # docs :list of document object need _id and _rev
    # update or create the docs
    def bulk_docs(docs)
      # allowed_options = %w'new_edits'

      options ||= {}
      options = JSON.parse(options.to_json)

      docs = JSON.parse(docs.to_json)

      # options.keys.each do |option|
      #   raise "Error option : #{option} not allowed in buld_docs" unless allowed_options.include?(option)
      # end
      docs = {'docs' => docs}
      @server.process_query(method: :post, uri: uri + '_bulk_docs', options: options, json: docs)

    end

    # save a document
    # doc can be a simple {}
    # batch: 'ok' to store in batch mode
    # if no _id in doc, the uuid if inserted from _uuids
    def save_doc(doc, batch: nil)

      unless doc.is_a?(Document)
        doc =  Document.new(doc, db: self)
      end

      doc.valid!

      # if doc['_attachments']
      #   doc['_attachments'] = encode_attachments(doc['_attachments'])
      # end

      doc._id = @server.uuids["uuids"].first if doc._id.nil?

      options = {}
      options[:batch] = batch  unless batch.nil?

      headers = {}
      headers = {"If-Match": doc._rev} unless doc._rev.nil?

      response = @server.process_query(method: :put, uri: uri + doc._id, options: options, json: doc, headers: headers)
      #response = @server.process_query(method: :post, uri: uri , options: options, body: doc.to_json)

      if response.has_key?('ok')
        doc._id = response['id']
        doc._rev = response['rev']
      else
        raise "Error saving doc #{doc._id}"
      end

      response
    end

    # attachment utility, get the mime type of a file
    def mime_for(path)
      mime = MIME::Types.type_for path
      mime.empty? ? 'text/plain' : mime[0].content_type
    end

    # saving attachments, without loading doc.
    # doc: with _id, name: attacment name, file: attachment source, mime type from the file.
    def save_attachments(doc, name, file, options: {})
      unless doc.is_a?(Document)
        doc =  Document.new(doc, db: self)
      end

      content_type = mime_for(file)
      headers = {'If-Match': doc._rev, 'Content-Type': content_type}
      resp = @server.process_query(method: :put, uri: uri + "/" + doc._id +  '/' + name , body: File.read(file), headers: headers )
      raise "Error puting attachment #{name}" unless resp['ok']==true

    end

    # delete this document (first get it)
    def delete_doc(doc)
      raise ArgumentError, "_id and _rev required for deleting" unless doc._id && doc._rev

      headers = {}
      headers = {"If-Match": doc._rev} unless doc._rev.nil?

      resp = @server.process_query(method: :delete, uri: uri + doc._id ,headers: headers)
      #response = @server.process_query(method: :delete, uri: uri + doc._id + "?rev=#{doc._rev}",headers: headers)
      raise "Error deleting doc #{doc._id}" unless resp['ok']==true
      resp
    end

    # true if exist.
    def exist?(docid)
      status, doc = @server.process_query_with_status(method: :head, uri: uri + docid)
      if status < 400
        true
      else
        false
      end
    end

    # list all index on db
    def index
      response = @server.process_query(method: :get, uri: uri + '_index')

      response
    end

    # create a new index
    def create_index(index)
      allowed_options = %w'index ddoc type name partitioned'
      index = JSON.parse(index.to_json)

      index.keys.each do |option|
        raise "Error option : #{option} not allowed in get" unless allowed_options.include?(option)
      end

      @server.process_query(method: :post, uri: uri + '_index', json: index)

    end

    # delete an index
    def delete_index(designdoc, name)

      @server.process_query(method: :delete, uri: uri + '_index/' + designdoc + '/json/' + name)

    end



    # return a partition from the database
    def partition(partition)
      Partition.new(partition, db: self)
    end

    def uri
      @server.uri.to_s + '/' + @db + '/'
    end

    def encode_attachments(attachments)
      attachments.each do |k,v|
        next if v['stub'] || v['data'].frozen?
        v['data'] = base64(v['data']).freeze
      end
      attachments
    end

    def base64(data)
      Base64.encode64(data).gsub(/\s/,'')
    end


  end
end
