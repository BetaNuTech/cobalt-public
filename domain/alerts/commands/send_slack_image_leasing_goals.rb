require 'imgkit'

module Alerts
  module Commands
    class SendSlackImageLeasingGoals
      def initialize(property_code, property_full_name, date, slack_channel, leasing_goals)
        @property_code = property_code
        @property_full_name = property_full_name
        @date = date
        @slack_channel = slack_channel

        @leasing_goals = leasing_goals
      end
      
      def perform
        if !Settings.slack_enabled
          puts "SendSlackImageLeasingGoals disabled"
          return
        end

        client = Slack::Web::Client.new
        
        begin
          # Read in template
          html = ""
          image_width = 420
          file = File.open("#{Rails.root}/other/assets/bluebot_leasing_goals_template.htm", "rb")
          html = file.read
          
          # <div class="cell even">
          #   <p class="agent">Heather Alsup</p>
          #   <progress max="100" value="92" class="css3"></progress>
          #   <p class="ratio">11/12</p>      
          # </div>
          # <div class="cell odd">
          #   <p class="agent">Jane Hall</p>
          #   <progress max="100" value="114" class="css3"></progress>
          #   <p class="ratio">8/7</p>              
          # </div>

          odd = false
          rows = ''
          @leasing_goals.each do |leasing_goal|
            agent = leasing_goal['agent']
            progress = leasing_goal['progress']
            ratio = leasing_goal['ratio']
            if odd
              rows += "<div class=\"cell odd\">"              
            else
              rows += "<div class=\"cell even\">"                            
            end
            rows += "<p class=\"agent\">#{agent}</p>"
            rows += "<progress max=\"100\" value=\"#{progress}\" class=\"css3\"></progress>"
            rows += "<p class=\"ratio\">#{ratio}</p>"
            rows += "</div>\n" 
            
            odd = !odd
          end

          html.gsub! "<!-- [ROWS] -->", rows

          
          kit = IMGKit.new(html, :quality => 100, :width => image_width)
          kit.stylesheets << "#{Rails.root}/other/assets/stylesheets/bluebot_leasing_goals.css"

          title = "#{@property_full_name}".titleize + " - #{@date.strftime('%b %Y')} Leasing Goals"
          image_filename = "#{@property_code}_leasing_goals.png"
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

          # if !response.nil? && !response["file"].nil?
          #   client.reactions_add(
          #     channel: @slack_channel,
          #     name: 'thumbsup',
          #     file: response["file"]["id"]
          #   )
          # end
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
