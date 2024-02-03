module Alerts
  module Commands
    class SendMaintBlueBotSlackMessage
      def initialize(message_text, channel)
        @message_text = message_text
        @channel = channel
      end
      
      def perform
        if !Settings.slack_enabled
          puts "SendMaintBlueBotSlackMessage disabled"
          return
        end

        token = ''
        if Settings.slack_test_mode == 'enabled'
          token = Settings.slack_maint_bluebot_api_token_test
        else
          token = Settings.slack_maint_bluebot_api_token
        end
        client = Slack::Web::Client.new(token: token)
        
        begin
          client.chat_postMessage(channel: @channel, text:   @message_text, 
            as_user: true, link_names: true)
        rescue => e
          Airbrake.notify(e, error_message: "Unable to send maint bluebot alert to Slack Channel #{@channel}")
        end
      end
    end

  end
end