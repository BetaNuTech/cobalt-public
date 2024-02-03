require 'imgkit'

module Alerts
  module Commands
    class SendMaintBlueBotTurnsGoalSlackImage
      def initialize(property_code, property_full_name, date, channel, turns, turns_goal, percent_of_goal, to_do_turns, days_since_goal_reached)
        @property_code = property_code
        @property_full_name = property_full_name
        @date = date
        @slack_channel = channel
        @turns = turns
        @turns_goal = turns_goal
        @percent_of_goal = percent_of_goal
        @to_do_turns = to_do_turns
        @days_since_goal_reached = days_since_goal_reached
      end
      
      def perform
        if !Settings.slack_enabled
          puts "SendMaintBlueBotTurnsGoalSlackImage disabled"
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
          # Save the image to a file
          # image_path = "#{Rails.root}/tmp/#{@filename}"
          # File.open(image_path, "wb") do |file|
          #   file.write @image
          # end

          # Read in template
          html = ""
          image_width = 680
          image_height = 400
          file = File.open("#{Rails.root}/other/assets/maint_bluebot_turns_goal_template.htm", "rb")
          html = file.read

          if @percent_of_goal > 100
            html.gsub! '[PROGRESS-BAR-VALUE]', '100'
            html.gsub! '[STATUSHTML]', "<p class=\"status color-black\">CONGRATULATIONS!<br /><strong><span class=\"status color-blue\">You exceeded your goal!</span></strong></p>"
          elsif @percent_of_goal == 100
            html.gsub! '[PROGRESS-BAR-VALUE]', '100'
            html.gsub! '[STATUSHTML]', "<p class=\"status color-black\">CONGRATULATIONS!<br /><strong><span class=\"status color-blue\">You met your goal!</span></strong></p>"
          else
            html.gsub! '[PROGRESS-BAR-VALUE]', '%0.f' % @percent_of_goal
            html.gsub! '[STATUSHTML]', "<p class=\"status color-black\">Missed turn goal for <strong><span class=\"status color-blue\">#{'%0.f' % @days_since_goal_reached}</span></strong> days in a row!</p>"
          end
          html.gsub! '[PERCENT]', '%0.f' % @percent_of_goal
          html.gsub! '[METRIC]', "#{'%0.f' % @turns}/#{'%0.f' % @turns_goal}"
          html.gsub! '[TODO]', "#{'%0.f' % @to_do_turns}"

          
          kit = IMGKit.new(html, :quality => 100, :width => image_width, :height => image_height)
          kit.stylesheets << "#{Rails.root}/other/assets/stylesheets/maint_bluebot_turns_goal.css"

          # Get the image BLOB
          # img = kit.to_img
          title = "#{@property_full_name}".titleize + " - #{@date.strftime('%b %e %Y')} Turns"
          image_filename = "maint_bluebot_turns_goal_#{@property_code}.png"
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
