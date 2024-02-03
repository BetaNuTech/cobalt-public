module Alerts
  module Commands
    class SendSlackMessage
      def initialize(message_text, channel)
        @message_text = message_text
        @channel = channel
      end
      
      def perform
        if !Settings.slack_enabled
          puts "SendSlackMessage disabled"
          return
        end

        client = Slack::Web::Client.new
        
        begin
          client.chat_postMessage(channel: @channel, text:   @message_text, 
            as_user: true, link_names: true)
        rescue => e
          Airbrake.notify(e, error_message: "Unable to send alert to Slack Channel #{@channel}")
        end
      end
    end

  end
end
