require 'imgkit'

module Alerts
  module Commands
    class SendSlackImageMonthlyLeasingStars
      def initialize(date, slack_channel, leasing_stars)
      # def initialize(property_code, property_full_name, date, slack_channel, leasing_stars)
        # @property_code = property_code
        # @property_full_name = property_full_name
        @date = date
        @slack_channel = slack_channel

        @leasing_stars = leasing_stars
      end
      
      def perform
        if !Settings.slack_enabled
          puts "SendSlackImageMonthlyLeasingStars disabled"
          return
        end

        client = Slack::Web::Client.new
        
        begin
          # Read in template
          html = ""
          image_width = 1240
          file = File.open("#{Rails.root}/other/assets/bluebot_monthly_leasing_stars_template.htm", "rb")
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

          html.gsub! "[MONTH]", @date.strftime('%b')

          html = html.force_encoding('UTF-8')

          odd = false
          rows = ''
          col1_max = (@leasing_stars.count.to_f / 3.0).ceil
          col2_max = col1_max * 2
          @leasing_stars.each_with_index do |leasing_star, index|
            agent = leasing_star['agent']
            property = leasing_star['property']
            goal = leasing_star['goal']
            sales = leasing_star['sales']
            # percentage = leasing_star['percentage']
            past_stars = leasing_star['past_stars']
            super_star = leasing_star['super_star'].present? && leasing_star['super_star'] == true ? "<img class=\"img-star\" src=\"data:image/png;base64,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\"> " : ""

            if odd
              rows += "<div class=\"cell odd\">"              
            else
              rows += "<div class=\"cell even\">"                            
            end
            agent_name = agent
            if past_stars > 0
              agent_name = "#{agent} (#{past_stars + 1})"
            end
            rows += "<p class=\"agent\">#{super_star}#{agent_name}</p>"
            rows += "<p class=\"property\">#{property}</p>"
            rows += "<p class=\"goal\">#{goal}</p>"
            rows += "<p class=\"sales\">#{sales}</p>"
            rows += "</div>\n" 
            
            odd = !odd

            if index == col1_max - 1
              rows = rows.force_encoding('UTF-8')
              html.gsub! "<!-- [ROWS_COL1] -->", rows
              odd = false
              rows = ''    
            elsif index == col2_max - 1
              rows = rows.force_encoding('UTF-8')
              html.gsub! "<!-- [ROWS_COL2] -->", rows
              odd = false
              rows = ''    
            elsif index == @leasing_stars.count - 1
              rows = rows.force_encoding('UTF-8')
              html.gsub! "<!-- [ROWS_COL3] -->", rows
            end
          end

          
          kit = IMGKit.new(html, :quality => 100, :width => image_width)
          kit.stylesheets << "#{Rails.root}/other/assets/stylesheets/bluebot_monthly_leasing_stars.css"

          title = "#{@date.strftime('%b %Y')} Leasing Stars"
          image_filename = "#{@date.strftime('%b_%Y')}_leasing_stars.png"
          # title = "#{@property_full_name}".titleize + " - #{@date.strftime('%b %Y')} Leasing Stars"
          # image_filename = "#{@property_code}_#{@date.strftime('%b_%Y')}_leasing_stars.png"
          
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
          puts e.message
          Airbrake.notify(e, error_message: "Unable to send image to Slack Channel #{@channel}")
        end
      end

      def error(job, exception)
        puts exception.message
        Airbrake.notify(exception, error_message: "Unable to send image to Slack Channel #{@channel}")
      end

      def failure(job)
        puts "Unable to send image to Slack Channel #{@channel}, job failed"
        Delayed::Worker.logger.debug("Unable to send image to Slack Channel #{@channel}, job failed")
      end

    end

  end
end
