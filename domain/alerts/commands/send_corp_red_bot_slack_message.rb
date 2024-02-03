module Alerts
  module Commands
    class SendCorpRedBotSlackMessage
      def initialize(message_text, channel)
        @message_text = message_text
        @channel = channel
      end
      
      def perform
        if !Settings.slack_enabled
          puts "SendCorpRedBotSlackMessage disabled"
          return
        end

        token = Settings.slack_corp_redbot_api_token
        client = Slack::Web::Client.new(token: token)
        
        begin
          client.chat_postMessage(channel: @channel, text: @message_text, 
            as_user: true, link_names: true)
        rescue => e
          Airbrake.notify(e, error_message: "Unable to send corp red bot alert to Slack Channel #{@channel}")
        end
      end
    end

  end
end