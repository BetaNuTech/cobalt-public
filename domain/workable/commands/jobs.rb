require 'httparty'
require 'cgi'

module Workable
  module Commands
    class Jobs
      include HTTParty

      # STATES
      # published
      # archived
      # closed

      SECRET_AUTH_TOKEN='WORKABLE_API_AUTH_TOKEN'

      def initialize(add_reposts:)
        @add_reposts = add_reposts
        @query = { 
          "limit"     => 1000
        }
        @headers = { 
          "Authorization" => "Bearer #{ENV.fetch(SECRET_AUTH_TOKEN)}" 
        }
        @url = "https://bluestone-properties.workable.com/spi/v3/jobs"
      end

      def perform

        paging = true
        @paging_next_url = nil

        data_saved = false

        while (paging)
          # Avoid 10 requests / 10 seconds limit, with production and staging running together.
          sleep 3
          result = get_jobs()

          if result[:error].present?
            return
          end
      
          # Process jobs
          json = result[:json_data]
          if json.present?
            # Checking next page
            if json["paging"].present?
              @paging_next_url = json["paging"]["next"]
            else
              @paging_next_url = nil
            end
            paging = @paging_next_url.present? ? true : false
      
            # Read in Jobs to Database
            jobs_array = json["jobs"]
            if jobs_array.present?
              jobs_array.each do |job|
                shortcode = job["shortcode"]
                if shortcode.nil?
                  next
                end

                code = job["code"]
                if code.nil? || code == ''
                  # Search for existing job, and delete them.
                  delete_job = WorkableJob.where(shortcode: shortcode).first
                  if delete_job.present?
                    delete_job.destroy
                  end
                  next
                end

                # Check if downcase " dup" exists in the code. 
                # If so, remove from code and set this job as a duplicate
                is_duplicate = false
                if code.downcase.include? ' dup'
                  code.sub!(' dup', '')
                  is_duplicate = true
                end

                # Check if downcase " void" exists in the code. 
                # If so, remove from code and set this job as a void (meaning clear and ignore activity)
                is_void = false
                if code.downcase.include? ' void'
                  code.sub!(' void', '')
                  is_void = true
                end

                # Check if downcase " noposting" exists in the code. 
                # If so, remove from code and set this job as a void (meaning clear and ignore activity)
                can_post = true
                if code.downcase.include? ' noposting'
                  code.sub!(' noposting', '')
                  can_post = false
                end

                # Check if downcase " newproperty" exists in the code
                # If so, remove from code and set this job as a void (meaning clear and ignore activity)
                new_property = false
                if code.downcase.include? ' newproperty'
                  code.sub!(' newproperty', '')  # just in case it was appended
                  new_property = true
                end

                # Remove any leading/trailing whitespace
                code.strip!

                property = Property.where('lower(code) = ?', code.downcase).first
                is_repost = false
                if property.nil? && !@add_reposts
                  # What until we process reposts
                  next
                elsif property.nil?
                  # This must be a repost, so match up to original Workable Job
                  # Search for matching job
                  # Set property from job
                  # Set original_job_shortcode
                  # Set original_job_created_at
                  original_job = WorkableJob.where(shortcode: code).first
                  if original_job.nil?
                    # If not found, we have an issue... ignore?  Delete this job, if already imported?
                    # Search for existing job, and delete them.
                    delete_job = WorkableJob.where(shortcode: shortcode).first
                    if delete_job.present?
                      delete_job.destroy
                    end
                    next
                  end
                  property = original_job.property
                  code = property.code # Set code to match Property/Team still
                  is_repost = true
                  original_job_created_at = original_job.job_created_at
                end

                # Create or Find Job
                workable_job = WorkableJob.where(shortcode: shortcode).first_or_initialize

                # Required to save job
                workable_job.code = code
                workable_job.property = property
                workable_job.job_created_at = job["created_at"].present? ? DateTime.parse(job["created_at"]) : nil
                workable_job.title = job["title"]
                workable_job.state = job["state"]
                workable_job.url = job["url"]

                # Not required
                workable_job.department = job["department"]
                workable_job.application_url = job["application_url"]
                workable_job.is_void = is_void
                workable_job.is_duplicate = is_duplicate
                workable_job.can_post = can_post
                workable_job.new_property = new_property
                workable_job.is_repost = is_repost
                # workable_job.original_job = original_job
                workable_job.original_job_created_at = original_job_created_at

                begin
                  workable_job.save!
                  data_saved = true
                rescue Exception => e
                  puts "Workable::Commands::Jobs - ERROR: #{e.message}"
                end
              end
            end

          else 
            # Stop while loop, since no data returned
            paging = false 
          end
      
        end

        if @add_reposts
          # Data Import Record
          new_record = DataImportRecord.apiJSON(
            source: DataImportRecordSource::WORKABLE, 
            data_date: nil, 
            data_datetime: nil, 
            title: DataImportRecordWorkableJSONTitle::Jobs)
          new_record.data_imported = data_saved
          new_record.save!
          new_record.sendNoficationToSlack()
        end

      end

      private

      def get_jobs
        http_response = nil
        error = nil
        begin
          if @paging_next_url.present?
            http_response = HTTParty.get(@paging_next_url, :headers => @headers)
          else
            http_response = HTTParty.get(@url, :query => @query, :headers => @headers)
          end
          json_data = http_response.parsed_response


        rescue
          message = "ERROR Workable::Commands::Jobs fetching data from #{@url}"
          Rails.logger.error(message)
          puts message
          error = message
        end

        if error.nil? && http_response.code != 200
          message = "ERROR: Workable API Jobs call failed (#{http_response.code})"
          Rails.logger.error(message)
          puts message
          error = message
        end

        puts "----------------------------------------"
        if error.nil?
          puts "Workable: Jobs Call SUCCESSFUL"
        else 
          puts "Workable: Jobs Call FAILED"
        end
        if @paging_next_url.present?
          puts "Paging URL: #{@paging_next_url}"
        end 
        puts "----------------------------------------"
        
        data = {json_data: json_data, error: error}
        # Rails.logger.debug data.inspect
        return data
      end

    end
  end
end
