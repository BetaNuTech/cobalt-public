require 'httparty'
require 'cgi'
require 'set'

module Workable
  module Commands
    class JobActivities
      include HTTParty

      SECRET_AUTH_TOKEN='WORKABLE_API_AUTH_TOKEN'

      def initialize(workable_job:)
        @workable_job = workable_job

        @query = { 
          "limit"     => 1000
        }
        @headers = { 
          "Authorization" => "Bearer #{ENV.fetch(SECRET_AUTH_TOKEN)}" 
        }
        @url = "https://bluestone-properties.workable.com/spi/v3/jobs/#{@workable_job.shortcode}/activities"
      end

      def perform

        paging = true
        @paging_next_url = nil

        # Properties that will be updated
        last_activity_member_name = nil
        last_activity_member_datetime = nil
        last_activity_member_action = nil
        last_activity_member_stage_name = nil
        last_activity_candidate_datetime = nil
        last_activity_candidate_action = nil
        last_activity_candidate_stage_name = nil
        last_offer_sent_at = nil
        offer_accepted_at = nil
        background_check_requested_at = nil
        background_check_completed_at = nil
        hired_at = nil
        candidate_id_offers_sent = Set.new

        # To match actions to same candidate
        hired_candidate_id = nil
        hired_candidate_name = nil
        background_check_completed_candidate_id = nil
        background_check_requested_candidate_id = nil
        offer_accepted_candidate_id = nil
        offer_sent_candidate_id = nil

        activities_array = []

        while (paging)
          # Avoid 10 requests / 10 seconds limit, with production and staging running together.
          sleep 3
          result = get_job_activities()

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
            
            # Parse Job Activities.
            # Assumption: Activities are already sorted by datetime, ascending.
            # Assumption: With paging, each page call will have newer activities
            if json["activities"].present?
              activities_array += json["activities"]
            end

          else 
            # Stop while loop, since no data returned
            paging = false 
          end
      
        end

        # Parse All Activities
        # Re-order activities to latest first
        activities_array.reverse.each do |activity|                
          if activity["action"].nil?
            puts "Job Activity: Missing action"
            next
          end

          action = activity["action"]

          # Assumption: If member exists, the action was made by member. Otherwise, it was the candidate.
          # Always update member activity if archived, because we can move to the previous non-archived action next
          # This makes sure we get to the 1st archived event.
          ignore_actions = ['archived', 'unarchived', 'published', 'unpublished', 'opened-confidentially', 'join-hiring-team']
          if last_activity_member_datetime.nil? && activity["member"].present? && !ignore_actions.include?(activity["action"])
            puts 'last member action: ' + activity["action"]
            last_activity_member_updated = true
            last_activity_member_name = activity["member"]["name"]
            last_activity_member_datetime = DateTime.parse(activity["created_at"])
            last_activity_member_action = activity["action"]
            last_activity_member_stage_name = activity["stage_name"]
          elsif last_activity_candidate_datetime.nil? && activity["candidate"].present? && activity["member"].nil?
            last_activity_candidate_datetime = DateTime.parse(activity["created_at"])
            last_activity_candidate_action = activity["action"]
            last_activity_candidate_stage_name = activity["stage_name"]
          end

          # If voided, ignore setting any other data (kept as nil)
          if @workable_job.is_void
            next
          end

          if activity["candidate"].nil?
            next
          end

          candidate = activity["candidate"]
          if candidate["id"].nil?
            puts "Job Activity: Missing candidate id"
            next
          end

          candidate_id = candidate["id"]
          candidate_name = candidate["name"]

          # Set the latest of each only
          case action
          when 'hired'
            if hired_candidate_id.nil?
              hired_candidate_id = candidate_id
              hired_candidate_name = candidate_name
              hired_at = DateTime.parse(activity["created_at"])
            end
          when 'background-check-completed'
            if background_check_completed_candidate_id.nil?
              background_check_completed_candidate_id = candidate_id
              background_check_completed_at = DateTime.parse(activity["created_at"])
            end
          when 'background-check-requested'
            if background_check_requested_candidate_id.nil?
              background_check_requested_candidate_id = candidate_id
              background_check_requested_at = DateTime.parse(activity["created_at"])
            end
          when 'offer-accepted'
            if offer_accepted_candidate_id.nil?
              offer_accepted_candidate_id = candidate_id
              offer_accepted_at = DateTime.parse(activity["created_at"])
            end
          when 'offer-sent'
            candidate_id_offers_sent << candidate_id
            if offer_sent_candidate_id.nil?
              offer_sent_candidate_id = candidate_id
              last_offer_sent_at = DateTime.parse(activity["created_at"])
            end
          else
            # Do nothing. Action a don't care
          end

        end

        # Make sure All Activities match the same candidate
        # Assumption: Offer Sent Candidate must match all other activities.
        if offer_sent_candidate_id != offer_accepted_candidate_id
          offer_accepted_at = nil
        end
        if offer_sent_candidate_id != background_check_requested_candidate_id
          background_check_requested_at = nil
        end 
        if offer_sent_candidate_id != background_check_completed_candidate_id
          background_check_completed_at = nil
        end 
        if offer_sent_candidate_id != hired_candidate_id
          hired_at = nil
          hired_candidate_name = nil
        end 

        # Add num of offers sent for this post
        @workable_job.num_of_offers_sent = candidate_id_offers_sent.count

        # Find other posts, if this is a repost, to add up other offers sent
        if @workable_job.is_repost
          @workable_job.other_num_of_offers_sent = 0
          original_post = WorkableJob.where(shortcode: @workable_job.code).first
          if original_post.present? && original_post.num_of_offers_sent.present?
            @workable_job.other_num_of_offers_sent += original_post.num_of_offers_sent
          end
          other_posts = WorkableJob.where(code: @workable_job.code).where.not(shortcode: @workable_job.shortcode)
          other_posts.each do |post|
            if post.num_of_offers_sent.present?
              @workable_job.other_num_of_offers_sent += post.num_of_offers_sent
            end
          end
        end

        # Update Workable Job
        #NOTE: If adding more data here, make sure to update voided data above
        @workable_job.last_activity_member_name = last_activity_member_name
        @workable_job.last_activity_member_datetime = last_activity_member_datetime
        @workable_job.last_activity_member_action = last_activity_member_action
        @workable_job.last_activity_member_stage_name = last_activity_member_stage_name
        @workable_job.last_activity_candidate_datetime = last_activity_candidate_datetime
        @workable_job.last_activity_candidate_action = last_activity_candidate_action
        @workable_job.last_activity_candidate_stage_name = last_activity_candidate_stage_name

        @workable_job.last_offer_sent_at = last_offer_sent_at
        @workable_job.offer_accepted_at = offer_accepted_at
        @workable_job.background_check_requested_at = background_check_requested_at
        @workable_job.background_check_completed_at = background_check_completed_at
        @workable_job.hired_at = hired_at
        @workable_job.is_hired = hired_at.present?
        @workable_job.hired_candidate_name = hired_candidate_name
        if hired_candidate_name.nil?
          @workable_job.hired_candidate_first_name = nil
          @workable_job.hired_candidate_last_name = nil
        else  
          name_array = hired_candidate_name.split(' ')
          @workable_job.hired_candidate_first_name = name_array.first
          @workable_job.hired_candidate_last_name = name_array.last
        end

        begin
          @workable_job.save!
        rescue Exception => e
          puts "Workable::Commands::JobActivites - ERROR: #{e.message}"
        end
      end

      private

      def get_job_activities
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
          message = "ERROR Workable::Commands::JobsActivities fetching data from #{@url}"
          Rails.logger.error(message)
          puts message
          error = message
        end

        if error.nil? && http_response.code != 200
          message = "ERROR: Workable::Commands::JobsActivities call failed (#{http_response.code})"
          Rails.logger.error(message)
          puts message
          error = message
        end

        puts "----------------------------------------"
        if error.nil?
          puts "Workable: Job Activities Call SUCCESSFUL"
        else 
          puts "Workable: Job Activities Call FAILED"
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
