require_relative "boot"
require "rails/all"

module Cellar
  class Application < Rails::Application
    config.load_defaults 8.0
    config.api_only = true
  end
end
