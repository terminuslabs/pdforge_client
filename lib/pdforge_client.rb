# frozen_string_literal: true
require_relative "pdforge_client/version"
require_relative "pdforge_client/config"
require_relative "pdforge_client/client"
begin
  require_relative "pdforge_client/railtie"
rescue LoadError
end

module PdforgeClient
  class << self
    def configure
      yield(config)
      @client = Client.new(config)
    end

    def config
      @config ||= Config.new
    end

    def client
      @client ||= Client.new(config)
    end

    def from_html(html, options = {})
      client.from_html(html, options)
    end

    def from_html_meta(html, options = {}, timeout_ms: nil)
      client.from_html_meta(html, options, timeout_ms: timeout_ms)
    end

    def from_url(url, options = {})
      client.from_url(url, options)
    end

    def from_docx(docx_bytes, options = {})
      client.from_docx(docx_bytes, options)
    end
  end
end
