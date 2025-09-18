# frozen_string_literal: true
require "openssl"
require "json"
require "httparty"

module PdforgeClient
  class Error < StandardError; end
  class RequestError < Error
    attr_reader :status, :body
    def initialize(msg, status:, body:)
      super(msg)
      @status = status
      @body = body
    end
  end

  class Client
    include HTTParty

    def initialize(config)
      @config = config
      @config.validate!
    end

    def from_html(html, options = {})
      payload = { html: html, options: merged_options(options) }
      post(payload)
    end

    def from_url(url, options = {})
      payload = { url: url, options: merged_options(options) }
      post(payload)
    end

    private

    def merged_options(opts)
      (@config.default_options || {}).merge(opts || {})
    end

    def sign(body)
      OpenSSL::HMAC.hexdigest("SHA256", @config.hmac_key, body)
    end

    def post(payload)
      body = payload.to_json
      headers = { "Content-Type" => "application/json", "x-signature" => sign(body) }
      resp = self.class.post(
        @config.endpoint,
        body: body,
        headers: headers,
        open_timeout: @config.open_timeout,
        read_timeout: @config.read_timeout
      )
      unless resp.code.to_i == 200
        raise RequestError.new("PdforgeClient PDF error: #{resp.code}", status: resp.code.to_i, body: resp.body.to_s)
      end
      resp.body # PDF bytes
    end
  end
end
