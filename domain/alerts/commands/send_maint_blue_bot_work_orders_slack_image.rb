require 'imgkit'

module Alerts
  module Commands
    class SendMaintBlueBotWorkOrdersSlackImage
      def initialize(property_code, property_full_name, date, channel, completed_wos, percent_of_goal, incomplete_wos)
        @property_code = property_code
        @property_full_name = property_full_name
        @date = date
        @slack_channel = channel
        @completed_wos = completed_wos
        @percent_of_goal = percent_of_goal
        @incomplete_wos = incomplete_wos
      end
      
      def perform
        if !Settings.slack_enabled
          puts "SendMaintBlueBotWorkOrdersSlackImage disabled"
          return
        end

        token = ''
        if Settings.slack_test_mode == 'enabled'
          token = Settings.slack_maint_bluebot_api_token_test
        else
          token = Settings.slack_maint_bluebot_api_token
        end
        client = Slack::Web::Client.new(token: token)

        begin

          # Read in template
          html = ""
          image_width = 680
          image_height = 400
          file = File.open("#{Rails.root}/other/assets/maint_bluebot_work_orders_template.htm", "rb")
          html = file.read

          if @percent_of_goal >= 100
            html.gsub! '[PROGRESS-BAR-VALUE]', '100'
            html.gsub! '[COMPLETED_STATUS]', "Wow! Great Work!!"
          elsif @percent_of_goal >= 90
            html.gsub! '[PROGRESS-BAR-VALUE]', '%0.f' % @percent_of_goal
            html.gsub! '[COMPLETED_STATUS]', "So close! Keep cranking!"
          elsif @percent_of_goal >= 80
            html.gsub! '[PROGRESS-BAR-VALUE]', '%0.f' % @percent_of_goal
            html.gsub! '[COMPLETED_STATUS]', "Keep up the good work!"
          elsif @percent_of_goal >= 65
            html.gsub! '[PROGRESS-BAR-VALUE]', '%0.f' % @percent_of_goal
            html.gsub! '[COMPLETED_STATUS]', "You can do this...the goal is in reach!"
          elsif @percent_of_goal >= 50
            html.gsub! '[PROGRESS-BAR-VALUE]', '%0.f' % @percent_of_goal
            html.gsub! '[COMPLETED_STATUS]', "Making progress"
          else
            html.gsub! '[PROGRESS-BAR-VALUE]', '%0.f' % @percent_of_goal
            html.gsub! '[COMPLETED_STATUS]', ""            
          end
          html.gsub! '[PERCENT]', '%0.f' % @percent_of_goal
          html.gsub! '[COMPLETED_METRIC]', "#{'%0.f' % @completed_wos}"
          html.gsub! '[INCOMPLETES_METRIC]', "#{'%0.f' % @incomplete_wos}"
          if @incomplete_wos == 0
            html.gsub! '[INCOMPLETES_STATUS]', "Congratulations!"
          elsif @incomplete_wos <= 2
            html.gsub! '[INCOMPLETES_STATUS]', "ALMOST TO GOAL!"
          else
            html.gsub! '[INCOMPLETES_STATUS]', "Should be ZERO!!"
          end

          
          kit = IMGKit.new(html, :quality => 100, :width => image_width, :height => image_height)
          kit.stylesheets << "#{Rails.root}/other/assets/stylesheets/maint_bluebot_work_orders.css"

          # Get the image BLOB
          # img = kit.to_img
          title = "#{@property_full_name}".titleize + " - #{@date.strftime('%b %e %Y')} Work Orders"
          image_filename = "maint_bluebot_work_orders_#{@property_code}.png"
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
