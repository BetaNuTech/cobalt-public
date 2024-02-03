# config/initializers/faraday.rb

require 'faraday'
require 'faraday/net_http'
require 'faraday/multipart'

Faraday.default_adapter = :net_http

# This doesn't work (yet?), for heroku-22, disabling ALL SSL for now.
Faraday.default_connection_options.ssl.verify = false