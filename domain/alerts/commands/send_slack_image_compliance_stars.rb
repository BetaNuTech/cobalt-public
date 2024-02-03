require 'imgkit'

module Alerts
  module Commands
    class SendSlackImageComplianceStars
      def initialize(date, slack_channel, compliance_stars)
        @date = date
        @slack_channel = slack_channel

        @compliance_stars = compliance_stars
      end
      
      def perform
        if !Settings.slack_enabled
          puts "SendSlackImageComplianceStars disabled"
          return
        end

        client = Slack::Web::Client.new
        
        begin
          # Read in template
          html = ""
          image_width = 420
          file = File.open("#{Rails.root}/other/assets/bluebot_compliance_stars_template.htm", "rb")
          html = file.read
          
          # html.gsub! "[MONTH]", @date.strftime('%b')

          odd = false
          rows = ''
          @compliance_stars.each do |compliance_star|
            property_manager = compliance_star['property_manager']
            property = compliance_star['property']
            # past_stars = compliance_star['past_stars']

            if odd
              rows += "<div class=\"cell odd\">"              
            else
              rows += "<div class=\"cell even\">"                            
            end
            # pm_name = property_manager
            # if past_stars > 0
            #   pm_name = "#{pm_name} (#{past_stars + 1})"
            # end
            rows += "<p class=\"property_manager\">#{property_manager}</p>"
            rows += "<p class=\"property\">#{property}</p>"
            rows += "</div>\n" 
            
            odd = !odd
          end

          html.gsub! "<!-- [ROWS] -->", rows

          
          kit = IMGKit.new(html, :quality => 100, :width => image_width)
          kit.stylesheets << "#{Rails.root}/other/assets/stylesheets/bluebot_compliance_stars.css"

          title = "#{@date.strftime('%b %d %Y')} - Compliance Stars"
          image_filename = "#{@date.strftime('%b_%d_%Y')}_compliance_stars.png"

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
