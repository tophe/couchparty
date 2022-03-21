module CouchParty

  # a Couchdb Doc, linked to db and partition
  # couchdb attributes is in doc attribut
  # usage:
  # doc._id
  # doc._rev
  # doc.doc['content']
  class Document

    attr_reader :db, :partition, :_attachments, :_id, :_rev, :doc

    # doc, change ruby symbol to string
    def initialize(doc, partition: nil, db: nil)
      @doc = JSON.parse(doc.to_json)
      @_id = @doc['_id'] if @doc.has_key?('_id')
      @_rev =@doc['_rev'] if @doc.has_key?('_rev')
      @_attachments = if @doc.has_key?('_attachements')
                       @doc['_attachments']
                     else
                       []
                     end
      if partition
        @partition = partition
        @db = partition.db
      else
        @db = db
      end
    end

    def _id=(value)
      doc['_id'] = value
    end
    def _rev=(value)
      doc['_rev'] = value
    end

    def _revs_info
      if doc.has_key?('_revs_info')
        doc['_revs_info']
      else
        []
      end
    end

    def _revisions
      if doc.has_key?('_revisions')
        doc['_revisions']
      else
        []
      end
    end

    # attachments facility
    def attachments
      unless @attachments
        @attachments = []
        _attachments.each do |attachment|
          @attachments << Attachment.new(attachment, nil,self)
        end
      end
    end

    def _attachments
      if doc.has_key?('_attachments')
        doc['_attachments']
      else
        {}
      end
    end

    def to_json(args = nil)
      @doc.to_json
    end

    # is the doc valid ie no ruby symbol in keys
    def valid!

      doc.keys.each do |key|
        raise "could not use symbol in doc : #{key} is a symbol" if key.is_a?(Symbol)
      end
    end

    def new!
      raise "doc need to be saved an must have a rev attribut" if _rev.nil?
      raise "database not set" unless db
    end

    def is_new?
      if _rev.nil?
        true
      else
        false
      end
    end

    # save the doc
    def save
      @db.save_doc(self)
    end

    # delete the doc
    def delete
      @db.delete_doc(self)
    end

    # fetch an attachment from doc
    def fetch_attachment(name, options: {})
      new!
      raise "Attachment #{name} not found" unless _attachments.has_key?(name)
      allowed_options = %w'rev'
      options ||= {}
      options.keys.each do |option|
        raise "Error option : #{option} not allowed in get" unless allowed_options.include?(option)
      end
      headers = {}
      headers = {'If-Match': options['rev']} if options.has_key?('rev')

      content = db.server.process_query(method: :get, uri: db.uri + "/" + _id +  '/' + name , headers: headers , no_json: true)
      attachment = Attachment.new(_attachments[name], content, self)

      attachment
    end

    # reload doc after a put_attachement
    def reload!
      new_doc = db.get(_id)
      @doc = new_doc.doc
      _rev = new_doc._rev

    end

    # put an attachment from a file, the file extension is used to find the mime-type
    def put_attachment(name, file, options: {}, reload: true)
      new!
      options ||= {}

      content_type = mime_for(file)
      headers = {'If-Match': _rev, 'Content-Type': content_type}
      resp = db.server.process_query(method: :put, uri: db.uri + "/" + _id +  '/' + name , body: File.read(file), headers: headers )
      raise "Error puting attachment #{name}" unless resp['ok']==true
      reload! if reload
    end

    # remove an attchement
    def delete_attachment(name, reload: true)
      new!
      headers = {'If-Match': _rev}
      resp = db.server.process_query(method: :delete, uri: db.uri + "/" + _id +  '/' + name , headers: headers )
      raise "Error puting attachment #{name}" unless resp['ok']==true
      reload! if reload
    end

    def mime_for(path)
      mime = MIME::Types.type_for path
      mime.empty? ? 'text/plain' : mime[0].content_type
    end


  end
end
