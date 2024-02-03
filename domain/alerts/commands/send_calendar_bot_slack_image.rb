require 'imgkit'
require 'humanize'

module Alerts
  module Commands
    class SendCalendarBotSlackImage
      def initialize(slack_channel, title, description, background_color, border_color, text_color)
        @slack_channel = slack_channel
        @title = title
        @description = description
        @background_color = background_color
        @border_color = border_color
        @text_color = text_color
      end
      
      def perform
        if !Settings.slack_enabled
          puts "SendCalendarBotSlackImage disabled"
          return
        end

        token = Settings.slack_calendarbot_api_token
        client = Slack::Web::Client.new(token: token)
        
        begin
          # Read in template
          html = ""
          image_width = 400
          file = File.open("#{Rails.root}/other/assets/calendarbot_template.htm", "rb")
          html = file.read

          # Validate Colors (ASSUMPTION: Colors are in #XXXXXX hex format)
          if @background_color.nil?
            # Default: Light blue
            @background_color = "#6ea8db"
          elsif @background_color.length == 6
            # Add '#', if missing
            @background_color = "#" + @background_color
          end

          if @border_color.nil?
            # Default: Light blue
            @border_color = "#6ea8db"
          elsif @border_color.length == 6
            # Add '#', if missing
            @border_color = "#" + @border_color
          end

          if @text_color.nil?
            # Default: White
            @text_color = "#ffffff"
          elsif @text_color.length == 6
            # Add '#', if missing
            @text_color = "#" + @text_color
          end

          html.gsub! '[TITLE]', @title
          html.gsub! '[DESC]', @description
          html.gsub! '[BKGRD_COLOR]', @background_color
          html.gsub! '[BORDER_COLOR]', @border_color
          html.gsub! '[TEXT_COLOR]', @text_color

          title_no_spaces = @title.gsub ' ', ''

          
          kit = IMGKit.new(html, :quality => 100, :width => image_width)

          # Get the image BLOB
          image_filename = "#{title_no_spaces}.png"
          # Save the image to a file
          tmp_path = Dir.mktmpdir(SecureRandom.hex)
          image_path = "#{tmp_path}/#{image_filename}"
          kit.to_file(image_path)
          puts "Writing #{image_filename} to #{tmp_path}"

          response = client.files_upload(
            channels: @slack_channel,
            as_user: true,
            file: Faraday::Multipart::FilePart.new(image_path, 'image/png'),
            title: @title,
            filename: image_filename,
            initial_comment: ''
          )
          puts response
        rescue => e
          Airbrake.notify(e, error_message: "Unable to send image to Slack Channel #{@slack_channel}")
        end
      end

      def error(job, exception)
        Airbrake.notify(exception, error_message: "Unable to send image to Slack Channel #{@slack_channel}")
      end

      def failure(job)
        Delayed::Worker.logger.debug("Unable to send image to Slack Channel #{@slack_channel}, job failed")
      end

    end

  end
end
