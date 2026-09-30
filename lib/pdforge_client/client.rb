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

    # Posts to /pdfmeta. Returns { pdf_data: String(binary), positions: Array }.
    def from_html_meta(html, options = {}, timeout_ms: nil)
      payload = {
        pipeline: "generate_pdf",
        html: html,
        options: merged_options(options),
        timeoutMs: timeout_ms || @config.render_timeout_ms
      }
      post_meta(payload, pdfmeta_endpoint)
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

    # "https://host/pdf" -> "https://host/pdfmeta"
    # "https://host"     -> "https://host/pdfmeta"
    def pdfmeta_endpoint
      ep = @config.endpoint.to_s.chomp("/")
      ep = ep.delete_suffix("/pdf")
      "#{ep}/pdfmeta"
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

    def post_meta(payload, url)
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
        raise RequestError.new("PdforgeClient PDF meta error: #{resp.code}", status: resp.code.to_i, body: resp.body.to_s)
      end

      parsed = resp.parsed_response
      raise Error, "PdforgeClient unexpected pdfmeta response" unless parsed.is_a?(Hash)

      pdf_base64 = parsed["pdf_base64"]
      raise Error, "PdforgeClient pdfmeta missing pdf_base64" unless pdf_base64.is_a?(String) && !pdf_base64.empty?

      positions = parsed["positions"]
      positions = [] if positions.nil?
      raise Error, "PdforgeClient pdfmeta positions must be an array" unless positions.is_a?(Array)

      {
        pdf_data: Base64.strict_decode64(pdf_base64),
        positions: positions
      }
    rescue ArgumentError
      raise Error, "PdforgeClient pdfmeta returned invalid base64"
    end
  end
end
