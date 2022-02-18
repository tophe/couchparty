
module CouchParty
  class Design < Document


    attr_reader :partition, :db, :ddoc

    def initialize(ddoc, doc, db: nil)
      @ddoc = ddoc

      doc = JSON.parse(doc.to_json)
      allowed_options = %w'_id _rev language options filters lists rewrites shows update_doc_update views autoupdate'
      doc.keys.each do |option|
        raise "Error option : #{option} not allowed in design doc" unless allowed_options.include?(option)
      end
      super(doc, db: db)


    end

    def _id
      '_design/'+ @ddoc
    end

    def partitioned?
      @doc.dig("options","partitioned")
    end
    # run this view
    #  GET /{db}/_design/{ddoc}/_view/{view}¶
    def view(view, partition: nil, options: {})
      allowed_options = %w'conflicts descending endkey end_key endkey_docid end_key_doc_id group group_level include_docs att_encoding_info
                        inclusive_end key keys limit reduce skip sorted stable stale startkey start_key startkey_docid start_key_doc_id update update_seq'

      # not supported
      unallowed_options = %w'attachments'

      options = JSON.parse(options.to_json)
      options.keys.each do |option|
        raise "Error option : #{option} not allowed in view query" unless allowed_options.include?(option)
      end

      raise "this view is partitioned, you must set the partition" if partitioned? && partition.nil?
      if partitioned?
        return @db.server.process_query(method: :get, uri: uri(partition) + "/_view/#{view}" , json: doc, options: options)
      else
        return @db.server.process_query(method: :get, uri: uri + "/_view/#{view}" , json: doc, options: options)
      end


    end

    # save this design
    def save
      headers = {}
      headers = {"If-Match": design._rev} unless _rev.nil?
      return @server.process_query(method: :put, uri: uri , json: doc, headers: headers)
    end


    # delete this desing
    def delete
      headers = {"If-Match": design._rev}
      return @db.server.process_query(method: :delete, uri: uri, headers: headers)
    end


    def uri(partition = nil)
      if partition.nil?
        @db.uri.to_s +  _id
      else
        @db.uri.to_s + "_partition/#{partition.to_s}/" +  _id
      end

    end


  end
end
