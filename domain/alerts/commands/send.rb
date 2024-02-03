module Alerts
  module Commands
    class Send
      def initialize(message_text, property_id)
        @message_text = message_text
        @property_id = property_id
      end
      
      def perform
        @property = Property.find(@property_id)
      
        send_slack_message if @property.slack_channel.present?
      rescue => e
        Airbrake.notify(e)
      end

      def send_slack_message
        send_slack_message = 
          Alerts::Commands::SendSlackMessage.new(@message_text, 
            @property.slack_channel)
        Job.create(send_slack_message)

      end
    end
  end
end
