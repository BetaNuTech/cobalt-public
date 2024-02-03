require 'imgkit'

module Alerts
  module Commands
    class SendSlackImageMonthlyLeasingSuperStar
      def initialize(date, slack_channel, name)
        @slack_channel = slack_channel
        @date = date
        @name = name
      end
      
      def perform
        if !Settings.slack_enabled
          puts "SendSlackImageMonthlyLeasingSuperStar disabled"
          return
        end

        client = Slack::Web::Client.new
        
        begin
          # Read in template
          html = ""
          image_width = 1091
          image_height = 618
          file = File.open("#{Rails.root}/other/assets/bluebot_monthly_leasing_super_star_template.htm", "rb")
          html = file.read

          html.gsub! "[NAME]", @name

          html = html.force_encoding('UTF-8')

          name_underscored = @name.gsub(' ', '_')
          

          kit = IMGKit.new(html, :quality => 100, :width => image_width, :height => image_height)
          kit.stylesheets << "#{Rails.root}/other/assets/stylesheets/bluebot_monthly_leasing_super_stars.css"

          title = "#{@date.strftime('%b %Y')} Leasing Super Star"
          image_filename = "#{@date.strftime('%b_%Y')}_leasing_super_star_#{name_underscored}.png"
          
          # Save the image to a file
          tmp_path = Dir.mktmpdir(SecureRandom.hex)
          image_path = "#{tmp_path}/#{image_filename}"
          kit.to_file(image_path)
          puts "Image saved to #{image_path}"

          response = client.files_upload(
            channels: @slack_channel,
            as_user: true,
            file: Faraday::Multipart::FilePart.new(image_path, 'image/png'),
            title: title,
            filename: image_filename,
            initial_comment: ''
          )
        rescue => e
          Airbrake.notify(e, error_message: "Unable to send image to Slack Channel #{@channel}")
        end
      end

      def error(job, exception)
        Airbrake.notify(exception, error_message: "Unable to send image to Slack Channel #{@channel}")
      end

      def failure(job)
        Delayed::Worker.logger.debug("Unable to send image to Slack Channel #{@channel}, job failed")
      end

    end

  end
end
