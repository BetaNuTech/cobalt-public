module Alerts
  module Commands
    class SendCorpYodaBotSlackMessage
      def initialize(message_text, channel)
        @message_text = message_text
        @channel = channel
      end
      
      def perform
        if !Settings.slack_enabled
          puts "SendCorpYodaBotSlackMessage disabled"
          return
        end

        token = Settings.slack_corp_yodabot_api_token
        client = Slack::Web::Client.new(token: token)
        
        begin
          client.chat_postMessage(channel: @channel, text: @message_text, 
            as_user: true, link_names: true)
        rescue => e
          Airbrake.notify(e, error_message: "Unable to send corp yoda bot alert to Slack Channel #{@channel}")
        end
      end
    end

  end
end