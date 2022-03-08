module CouchParty

  # common task in databases and partitions
  module Finder

    # get _all_docs
    def all_docs(options: {})
      allowed_options = %w'conflicts descending endkey end_key endkey_docid end_key_doc_id group group_level include_docs att_encoding_info
                        inclusive_end key keys limit reduce skip sorted stable stale startkey start_key startkey_docid start_key_doc_id update update_seq'

      # not supported
      unallowed_options = %w'attachments'

      options = JSON.parse(options.to_json)
      options.keys.each do |option|
        raise "Error option : #{option} not allowed in view query" unless allowed_options.include?(option)
      end

      @server.process_query(method: :get, uri: uri + '_all_docs', options: options )
    end

    # post _find
    # json : send in body calling .to_json
    def find(json , options: {})
      body_params = %w'selector limit skip sort fields use_index conflicts r bookmark update stable stale execution_stats'
      json = JSON.parse(json.to_json)
      json.each_key do |k|
        raise "selector : #{k} not permited " unless body_params.include?(k)
      end

      @server.process_query(method: :post, uri: uri + '_find', options: options, json: json)
    end


    def info
      @server.process_query(method: :get, uri: uri )
    end

  end
end

