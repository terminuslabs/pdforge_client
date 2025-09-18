# frozen_string_literal: true
module PdforgeClient
  class Config
    attr_accessor :endpoint, :hmac_key, :open_timeout, :read_timeout, :default_options

    def initialize
      @endpoint = ENV["PDF_SERVICE_URL"]
      @hmac_key = ENV["PDF_HMAC_KEY"]
      @open_timeout = 5
      @read_timeout = 30
      @default_options = { printBackground: true, format: "Letter" }
    end

    def validate!
      raise ArgumentError, "PdforgeClient endpoint not configured" if @endpoint.to_s.strip.empty?
      raise ArgumentError, "PdforgeClient hmac_key not configured" if @hmac_key.to_s.strip.empty?
    end
  end
end
