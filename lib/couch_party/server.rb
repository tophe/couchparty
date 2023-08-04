require 'json'

module CouchParty
  class Server

    # Connection object prepared on initialization
    attr_reader :session, :uri, :logger

    def request_factory(type, url, headers)

      case type
      when :get
        request = Net::HTTP::Get.new url
      when :post
        request = Net::HTTP::Post.new url
      when :put
        request = Net::HTTP::Put.new url
      when :head
        request = Net::HTTP::Head.new url
      when :delete
        request = Net::HTTP::Delete.new url
      end


      @request_headers.each do |header, value|
        request[header] = value
      end
      headers.each do |header, value|
        request[header] = value
      end

      request.basic_auth @basic_auth[:user], @basic_auth[:password] if @basic_auth



      request['Cookie'] = HTTP::Cookie.cookie_value(@jar.cookies(url))

      request
    end

    # create a new server
    # from url
    # name: user name
    # password: password
    # setting name and password use couchdb session authentication
    # logger: set a ruby logger
    # options: gzip: true, proxy_host, proxy_port, http_timeout
    # option
    def initialize(url: 'http://localhost:5984', name: nil, password: nil, logger: nil, gzip: false, proxy_host: nil, proxy_port: nil, read_timeout: 60 )
      if ENV['COUCHPARTY_DEBUG']
        puts "CouchParty debug mode on"
        puts "proxy set to #{ENV["http_proxy"]}" if ENV["http_proxy"]
      end

      @gzip = false

      @uri = prepare_uri(url).freeze
      @logger = logger

      @jar = HTTP::CookieJar.new

      @request_headers =   {'content-type' => 'application/json',
                            'Accept' => 'application/json',
                            'User-Agent' => "CouchParty-#{CouchParty::VERSION}"}

      @request_headers['Content-Encoding'] = "gzip" if @gzip

      if proxy_host & proxy_port
        @proxy_host = proxy_host
        @proxy_port = proxy_port
      end
      @read_timeout = read_timeout

      ENV.delete("http_proxy")

      if @proxy_host
        @session = Net::HTTP.start(@uri.host, @uri.port, @proxy_host, @proxy_port, use_ssl: uri.scheme == 'https')
      else
        @session = Net::HTTP.start(@uri.host, @uri.port, use_ssl: uri.scheme == 'https', read_timeout: @read_timeout)
      end

      # basic auth deprecated for cookie auth
      unless @uri.user.nil?
        @basic_auth = {user: @uri.user, password: @uri.password}
      end

      # cookie auth
      unless name.nil?
        @cookie_auth = {name: name, password:  password }
        auth

      end

    end

    # true if using a cookie auth
    def cookie_auth?
      @cookie_auth.nil? ? false : true
    end

    def clear_auth
      resp = process(method: :delete, uri: @uri + '_session')
    end

    # cookie auth
    def auth
      resp = process(method: :post, uri: @uri + '_session', json: @cookie_auth)
      raise "Error #{resp.error.message}" if resp.code.to_i >= 500

      if resp.code.to_i == 200
        result = JSON.parse(resp.body.to_s)
        if result['ok'] == true
          resp.get_fields('Set-Cookie').each do |value|
            @jar.parse(value, @uri)
          end
          puts "auth success #{resp.get_fields('Set-Cookie')}" if ENV['COUCHPARTY_DEBUG']
          log(:info, "authent success #{resp.get_fields('Set-Cookie')}")
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
      raise response.message if response.code.to_i >= 500
    end

    def uuids
      process_query(method: :get, uri: @uri + '/_uuids'  )
    end

    def active_tasks
      process_query(method: :get, uri: @uri + '/_active_tasks'  )
    end

    def exist?(db:)
      status, repsonce =  process_query_with_status(method: :head, uri: @uri + db  )
      return false if status == 404
      return true
    end

    def db(db: )
      if exist?(db: db)
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

      [response.code.to_i, response]
    end

    def process_query(method:, uri:, options: {}, body: nil, headers: {}, json: nil, no_json: false)

      response = process(method: method, uri: uri, options: options, body: body, headers: headers, json:json)


      raise CouchError.new(response) if response.code.to_i >= 300

      if no_json
        response.body
      else
        JSON.parse(response.body)
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

      request = request_factory(method,  puri, headers)

      if body
        content = body
      else
        content = json.to_json
      end

      if content && @gzip

        # write content to a file need to use tempfile
        File.open('json.json','w') { |io| io.puts(json.to_json)}

        # read content in bin mode
        content_bin= File.new('json.json','rb').read
        sio = StringIO.new
        sio.binmode
        @gziper = Zlib::GzipWriter.new(sio)
        #@gziper.write r
        @gziper << content_bin
        content = @gziper.close.string
      end


      if [:put, :post].include?(method)
        response = @session.request(request, content)
      else
        response = @session.request(request)
      end


      # must reauth in case 401, and cookie auth
      if response.code.to_i == 401 && cookie_auth?
        puts 'cookie timed out ! reauth and retry' if ENV['COUCHPARTY_DEBUG']

        auth

        process(method: method, uri: uri, options: options, body: body, headers: headers, json: json)

      else
        log(:info, "#{method}\t#{uri}\t#{options}\tin #{((Time.now - start_time)*1000).round(3)} ms")
        raise "Error #{response.message}" if response.code.to_i >= 500
        response

      end

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
