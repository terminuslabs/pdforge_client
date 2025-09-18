# frozen_string_literal: true
require "rails/railtie"

module PdforgeClient
  class Railtie < ::Rails::Railtie
    config.pdforge_client = PdforgeClient::Config.new

    initializer "pdforge_client.configure" do |_app|
      # apps can override config in config/initializers/pdforge_client.rb
    end
  end
end
