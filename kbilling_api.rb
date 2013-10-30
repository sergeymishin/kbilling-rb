# encoding: utf-8
#

module KBilling
  class API
    attr_accessor :api_key
    
    def initialize api_endpoint, api_key = nil
      @api_endpoint = api_endpoint 
      @api_key = api_key
    end
    
    
    def connection
      return @connection if @connection
      
      @connection = Faraday::Connection.new()
      @connection.headers['Content-Type'] = 'application/json'
      @connection.basic_auth('', @api_key)
      @connection
    end
    
    def get method, params = {}
      handle_response connection.get("#{@api_endpoint}/#{method}", params)
    end
    
    def put method, params = {}
      response = connection.put do |req|
        req.url "#{@api_endpoint}/#{method}"
        req.body = params.to_json
      end
      handle_response response
    end
    
    
    def handle_response response
      response = ActiveSupport::JSON.decode(response.body)
      
      raise ServerError.new self, method, params, response['error'] if response['error']
      response
    end
    
    def get_client client_id
      self.get "clients/#{client_id}"
    end
    
    def create_client client_id
      self.put "clients/#{client_id}", {:txn => uuid_generate}
    end
    
    def create_transaction txn_id, params
      self.put "txns/#{txn_id}", {:ops => params}
    end
    
    def uuid_generate
      SecureRandom.uuid
    end
  end
  
  
  class Error < ::StandardError; end
  
  class ServerError < Error
    attr_accessor :session, :method, :params, :error
    def initialize(session, method, params, error)
      super "Server side error calling KBilling method: #{error}"
      @session, @method, @params, @error = session, method, params, error
    end
  end
  
end
