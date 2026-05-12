# frozen_string_literal: true
require "openssl"
require "base64"
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
      post(payload, @config.endpoint)
    end

    def from_url(url, options = {})
      payload = { url: url, options: merged_options(options) }
      post(payload, @config.endpoint)
    end

    def from_docx(docx_bytes, options = {})
      encoded = Base64.strict_encode64(docx_bytes.b)
      payload = { docx: encoded, options: merged_options(options) }
      post(payload, docx_endpoint)
    end

    private

    def merged_options(opts)
      (@config.default_options || {}).merge(opts || {})
    end

    def sign(body)
      OpenSSL::HMAC.hexdigest("SHA256", @config.hmac_key, body)
    end

    # Derive the DOCX endpoint from the configured endpoint:
    #   - "https://host/pdf"  -> "https://host/pdf/docx"  (backward-compat for callers
    #     whose `endpoint` already points at the /pdf route)
    #   - "https://host"      -> "https://host/pdf/docx"
    def docx_endpoint
      ep = @config.endpoint.to_s
      ep.end_with?("/pdf") ? "#{ep}/docx" : "#{ep.chomp('/')}/pdf/docx"
    end

    def post(payload, url)
      body = payload.to_json
      headers = { "Content-Type" => "application/json", "x-signature" => sign(body) }
      resp = self.class.post(
        url,
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
