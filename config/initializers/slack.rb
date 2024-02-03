Slack::Web::Client.configure do |config|
  if Settings.slack_test_mode == 'enabled'
    config.token = Settings.slack_api_token_test
  else
    config.token = Settings.slack_api_token
  end

  # config.ca_file = OpenSSL::X509::DEFAULT_CERT_FILE
  # config.ca_path = OpenSSL::X509::DEFAULT_CERT_DIR
end
