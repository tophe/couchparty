require 'json'

module CouchParty
  class Server

    # Connection object prepared on initialization
    attr_reader :session, :uri, :logger

    def initialize(url: 'http://localhost:5984', name: nil, password: nil, logger: nil, options: {})
      puts "CouchParty debug mode on"  if ENV['COUCHPARTY_DEBUG']
      @uri = prepare_uri(url).freeze
      @logger = logger

      @session = HTTPX.plugin(:persistent)
                      .with_headers('content-type' => 'application/json')
                      .with_headers('Accept' => 'application/json')
                      .with_headers('User-Agent' => "CouchParty/#{CouchParty::VERSION}")
                      .with(resolver_class: :system)

      # debug purpose, set up a local proxy, ex: charles
      # https://www.charlesproxy.com/
      @session = @session.plugin(:proxy).with_proxy(uri: 'http://localhost:8888') if ENV['COUCHPARTY_PROXY']

      if ENV.has_key?('HTTP_PROXY')
        @session = @session.plugin(:proxy).with_proxy(uri: ENV['HTTP_PROXY'])
      end

      # basic auth deprecated for cookie auth
      unless @uri.user.nil?
        @session = @session
                        .plugin(:basic_authentication)
                        .basic_auth(@uri.user, @uri.password)
      end

      unless name.nil?
        @auth_h = {name: name, password:  password }
        @session = @session.plugin(:cookies)
        auth

      end

    end

    # true if using a cookie auth
    def cookie_auth?
      @auth_h.nil? ? false : true
    end

    def clear_auth
      resp = process(method: :delete, uri: @uri + '_session')
    end

    # cookie auth
    def auth
      resp = process(method: :post, uri: @uri + '_session', json: @auth_h)
      raise "Error #{resp.error.message}" if resp.is_a?(HTTPX::ErrorResponse)


      if resp.status == 200
        result = JSON.parse(resp.body.to_s)
        if result['ok'] == true
          puts "auth success #{resp.headers["set-cookie"]}" if ENV['COUCHPARTY_DEBUG']
          log(:info, "authent success #{resp.headers["set-cookie"]}")
          # succeed
          # httpx manage the cookie
        end


      else
        raise CouchError.new(resp.error)
      end

    end

    # create database
    # return database
    def create(db: , options: {})
      allowed_options = %w'n q partitioned'
      options = JSON.parse(options.to_json)

      options.keys.each do |option|
        raise "Error option : #{option} not allowed in get" unless allowed_options.include?(option)
      end

      # truthy
      %w'partitioned'.each do |opt|
        options[opt] = true if options.has_key?(opt)
      end

      ret = process_query(method: :put, uri: @uri + '/' + db, options: options )

      if ret['ok'] == true
        return Database.new(server: self, db: db)
      end

    end

    # delete database
    def delete(db: )
      status, response = process_query_with_status(method: :delete, uri: @uri + '/' + db  )
      raise response.error if response.status >= 500
    end

    def uuids
      process_query(method: :get, uri: @uri + '/_uuids'  )
    end

    def active_tasks
      process_query(method: :get, uri: @uri + '/_active_tasks'  )
    end

    def db(db: )
      if all_dbs.include?(db)
        return Database.new(server: self, db: db)
      else
        raise "database: #{db} not found"
      end
    end

    # Lists all databases on the server
    def all_dbs
      process_query(method: :get, uri: @uri + '/_all_dbs' )
    end

    def info
      process_query(method: :get, uri: @uri + '/' )
    end


    def log(level, info)
      if @logger
        @logger.send(level, info)
      end
    end

    def process_query_with_status(method:, uri:, options: {}, body: nil, headers: {}, json: nil, no_json: false)
      response = process(method: method, uri: uri, options: options, body: body, json: json)

      [response.status, response]
    end

    def process_query(method:, uri:, options: {}, body: nil, headers: {}, json: nil, no_json: false)

      response = process(method: method, uri: uri, options: options, body: body, headers: headers, json:json)


      #raise response.error if response.status >= 300
      raise CouchError.new(response.error) if response.status >= 300

      if no_json
        response.body
      else
        JSON.parse(response.to_s)
      end


    end


    # central method for acting on couch
    # method: http method (:get, :put ...)
    # uri: http uri
    # options : injected in uri.query
    # body: body injected in post / put request as is it
    # headers: add to http query headers
    # json: injected in pot/put query with .to_json
    def process(method:, uri:, options: {}, body: nil, headers: {}, json: nil)

      puts "method: #{method}\turi: #{uri}\toptions: #{options}\tbody: #{body}\theaders: #{headers}\tjson: #{json.to_json}" if ENV['COUCHPARTY_DEBUG']

      puri = URI(uri.to_s)

      query_str = options.collect { |name, value| "#{name}=#{value}"}.join('&')
      unless query_str.empty?
        if puri.query
          puri.query += '&' + query_str
        else
          puri.query = query_str
        end
      end

      # puts uri
      start_time = Time.now
      if [:put, :post].include?(method)
        ret = @session.send(method, puri, body: body, headers: headers, json: json)
      else
        ret = @session.send(method, puri, headers: headers)
      end

      # must reauth in case 401, and cookie auth
      if ret.status == 401 && cookie_auth?
        puts 'cookie timed out ! reauth and retry' if ENV['COUCHPARTY_DEBUG']

        auth
        if [:put, :post].include?(method)
          ret = @session.send(method, puri, body: body, headers: headers, json: json)
        else
          ret = @session.send(method, puri, headers: headers)
        end

      end

      log(:info, "#{method}\t#{uri}\t#{options}\tin #{((Time.now - start_time)*1000).round(3)} ms")
      raise "Error #{ret.error.message}" if ret.is_a?(HTTPX::ErrorResponse)
      ret
    end

    def prepare_uri(url)
      uri = URI(url)
      uri.path     = ''
      uri.query    = nil
      uri.fragment = nil
      uri
    end

  end
end
