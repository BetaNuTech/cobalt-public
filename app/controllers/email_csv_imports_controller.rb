class EmailCsvImportsController < ApplicationController
  require 'mail'
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  
  http_basic_authenticate_with name: Settings.basic_auth_username, 
    password: Settings.basic_auth_password
  
  def create
    # Upload to S3
    s3 = Aws::S3::Resource.new
    timestamp = Time.now.strftime "%Y-%m-%d_%H%M%SUTC"
    obj = s3.bucket(Settings.s3_bucket).object("uploads/csv_files/#{timestamp}.csv")

    # If cloudmailin isn't sending attachments to S3, then pull directly from path
    if params[:attachments].present? && params[:attachments]['0'].class == ActionController::Parameters
      attachment_url = params[:attachments]['0']['url']
      if attachment_url.present? && attachment_url.end_with?("csv")
        obj.upload_file(attachment_url, acl:'public-read')
        command = Metrics::Commands::ImportCsvFile.new(obj.public_url)
        Job.create(command)
      end 
    elsif params[:attachments].present? && params[:attachments]['0'].class = ActionDispatch::Http::UploadedFile && params[:attachments]['0'].path.present?
      attachment_path = params[:attachments]['0'].path
      if attachment_path.present? && attachment_path.end_with?("csv")
        obj.upload_file(attachment.path, acl:'public-read')
        command = Metrics::Commands::ImportCsvFile.new(obj.public_url)
        Job.create(command)
      end
    else  
      Airbrake.notify("Unable to parse attachment for EmailCsvImportsController")
    end
    
    render text: 'success', status: 200
  end
end
