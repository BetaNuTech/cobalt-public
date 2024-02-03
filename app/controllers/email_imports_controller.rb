class EmailImportsController < ApplicationController
  require 'mail'
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  
  http_basic_authenticate_with name: Settings.basic_auth_username, 
    password: Settings.basic_auth_password
  
  def create
    root_url = "#{request.protocol}#{request.host}"

    @logger = Logger.new(STDOUT)
    @logger.debug "Email attachments:\n#{params[:attachments]}\n"

    attachment_index = 0

    while params[:attachments]["#{attachment_index}"].present?
      
      # If cloudmailin isn't sending attachments to S3, then pull directly from path and upload to S3 first
      if params[:attachments]["#{attachment_index}"].is_a?(ActionController::Parameters)
        attachment_url = params[:attachments]["#{attachment_index}"]['url']

        if attachment_url.present? && attachment_url.end_with?("xlsx")
          begin
            command = Metrics::Commands::ImportExcelSpreadsheet.new(attachment_url, root_url)
            Job.create(command)
          rescue => e
            Airbrake.notify(e, error_message: "Unable to create ImportExcelSpreadsheet job, using url")
          end
        end
      elsif params[:attachments]["#{attachment_index}"].is_a?(ActionDispatch::Http::UploadedFile)
        attachment_path = params[:attachments]["#{attachment_index}"].path
        
        # Check for .xlsx extension
        if attachment_path.present? && attachment_path.end_with?("xlsx")
          @logger.debug "Importing attachment: #{attachment_path}"

          # Upload to S3
          s3 = Aws::S3::Resource.new
          filename = Time.now.strftime "%Y-%m-%d_%H%M%S%L_UTC_#{attachment_index}"
          @logger.debug "Created Filename for S3: #{filename}"
          obj = s3.bucket(Settings.s3_bucket).object("uploads/xlsx_files/#{filename}.xlsx")
          obj.upload_file(attachment_path, acl:'public-read')
          begin
            @logger.debug "Attachment uploaded to S3: #{obj.public_url}"
            command = Metrics::Commands::ImportExcelSpreadsheet.new(obj.public_url, root_url)
            Job.create(command)
          rescue => e
            Airbrake.notify(e, error_message: "Unable to create ImportExcelSpreadsheet job, using path")
          end
        end
      else  
        Airbrake.notify("Unable to parse attachment for ImportExcelSpreadsheet")
      end

      attachment_index += 1
    end

    render text: 'success', status: 200
  end
end
