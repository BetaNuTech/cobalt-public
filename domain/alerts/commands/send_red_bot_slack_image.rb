module Alerts
  module Commands
    class SendRedBotSlackImage
      def initialize(channel, title, image_filename, send_as_blue_bot)
        @channel = channel
        @title = title
        @image_filename = image_filename
        @send_as_blue_bot = send_as_blue_bot
      end
      
      def perform
        if !Settings.slack_enabled
          puts "SendRedBotSlackImage disabled"
          return
        end
        
        token = ''
        if Settings.slack_test_mode == 'enabled'
          token = Settings.slack_redbot_api_token_test
        else
          token = Settings.slack_redbot_api_token
        end
        client = Slack::Web::Client.new(token: token)

        if @send_as_blue_bot
          client = Slack::Web::Client.new
        end

        begin
          image_path = "#{Rails.root}/other/assets/images/#{@image_filename}"

          client.files_upload(
            channels: @channel,
            as_user: true,
            file: Faraday::Multipart::FilePart.new(image_path, 'image/png'),
            title: @title,
            filename: @image_filename,
            initial_comment: ''
          )
        rescue => e
          Airbrake.notify(e, error_message: "Unable to send red bot image to Slack Channel #{@channel}")
        end
      end

      def error(job, exception)
        Airbrake.notify(exception, error_message: "Unable to send red bot image to Slack Channel #{@channel}")
      end

      def failure(job)
        Delayed::Worker.logger.debug("Unable to send red bot image to Slack Channel #{@channel}, job failed")
      end

    end

  end
end
