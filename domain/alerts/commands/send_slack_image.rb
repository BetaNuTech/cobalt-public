require 'imgkit'
require 'humanize'

module Alerts
  module Commands
    class SendSlackImage
      def initialize(property_code, property_full_name, date, slack_channel, percent_of_goal, leases_attained, total_lease_goal, leases_message, leases_attained_delta, days_of_no_leases)
        @property_code = property_code
        @property_full_name = property_full_name
        @date = date
        @slack_channel = slack_channel
        @percent_of_goal = percent_of_goal
        @leases_attained = leases_attained
        @leases_attained_delta = leases_attained_delta
        @total_lease_goal = total_lease_goal
        @leases_message = leases_message
        @days_of_no_leases = days_of_no_leases
      end
      
      def perform
        if !Settings.slack_enabled
          puts "SendSlackImage disabled"
          return
        end

        client = Slack::Web::Client.new
        
        begin
          # Save the image to a file
          # image_path = "#{Rails.root}/tmp/#{@filename}"
          # File.open(image_path, "wb") do |file|
          #   file.write @image
          # end

          # Read in template
          html = ""
          image_width = 400
          if @days_of_no_leases >= 4
            file = File.open("#{Rails.root}/other/assets/bluebot_zero_for_x_days_template.htm", "rb")
          else
            file = File.open("#{Rails.root}/other/assets/bluebot_template_noalert.htm", "rb")
          end
          html = file.read
          # if alert_message == ''
          #   file = File.open("#{Rails.root}/other/assets/bluebot_template_noalert.htm", "rb")
          #   html = file.read
          # else
          #   file = File.open("#{Rails.root}/other/assets/bluebot_template.htm", "rb")
          #   html = file.read
          #   html.gsub! '[ALERT]', alert_message
          #   image_width = 500
          # end

          percent_of_month = @date.mday.to_f / Date.new(@date.year, @date.month, -1).mday.to_f * 100.0

          html.gsub! '[DAYS]', @days_of_no_leases.humanize.upcase
          html.gsub! '[PERCENT]', @percent_of_goal
          html.gsub! '[PERCENT_OF_MONTH]', "#{percent_of_month}"
          html.gsub! '[STATUS]', @leases_message
          html.gsub! '[STATS]', "#{@leases_attained}/#{@total_lease_goal}"
          if @date.mday == 1 || @leases_attained_delta.nil?
            html.gsub! '[DELTA]', ''                        
          else
            html.gsub! '[DELTA]', "#{@leases_attained_delta}"                        
          end


          kit = IMGKit.new(html, :quality => 100, :width => image_width)
          if @days_of_no_leases >= 4
            kit.stylesheets << "#{Rails.root}/other/assets/stylesheets/bluebot_zero_for_x_days.css"
          else
            kit.stylesheets << "#{Rails.root}/other/assets/stylesheets/bluebot.css"
          end

          # Get the image BLOB
          # img = kit.to_img
          title = "#{@property_full_name}".titleize + " - #{@date.strftime('%b %Y')} Sales Goals"
          image_filename = "#{@property_code}.png"
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
