require 'httparty'
require 'cgi'

module Sparkle
  module Commands
    class LatestInspection
      include HTTParty

      def initialize(property:, template:, created_on:)
        @property = property
        
        # @url = "https://us-central1-sapphire-inspections.cloudfunctions.net/api/v1/properties/#{@property.code}/latest-inspection?other_date=#{other_date_unixtime}"

        # if Settings.host == 'cobalt-dev.herokuapp.com' || Settings.host == 'localhost:3000'
        #   @url = "https://us-central1-sapphire-inspections-staging.cloudfunctions.net/api/v0/inspections/latest-completed?propertyCode=#{@property.code}"
        # else
        @url = "https://us-central1-sapphire-inspections.cloudfunctions.net/api/v0/inspections/latest-completed?propertyCode=#{@property.code}"
        # end
        
        # If created_on exists, then request the latest completed inspection before blueshift, created_on date
        if created_on.present?
          before_unixtime = created_on.to_time.to_i
          @url = @url + "&before=#{before_unixtime}"
        end

        # If a template is defined for property's Blueshift PM, then request inspection made with the template
        if template.present?
          @url = @url + "&templateName=#{CGI.escape(template)}"
        end

      end

      def perform
        http_response = nil
        error = nil
        begin
          http_response = HTTParty.get(@url)
          json_data = http_response.parsed_response
          puts "--- Sparkle: Latest Inspection Response for #{@property.code} ---"
          puts json_data
          latest_inspection = nil
          latest_inspection_by_date = nil
          property_data = nil

          # latest inspection JSON
          if json_data["data"].present? && json_data["data"].kind_of?(Hash)
            if json_data["data"]["attributes"].present? && json_data["data"]["attributes"]["creationDate"].present?
              latest_inspection = json_data["data"]["attributes"]
            end
            # if json_data["meta"].present?
            #   latest_inspection["meta"] = json_data["meta"]
            # end
          end

          if json_data["included"].present? && json_data["included"].kind_of?(Array)
            json_data["included"].each do |data|
              if data["type"].present? && data["type"] == "property"
                property_data = data["attributes"]
              end
            end
          end

          # # other_date inspection JSON
          # included = json_data["included"]
          # if included.present? && included.count >= 1 
          #     if included[0]["attributes"]["creationDate"].present?
          #       latest_inspection_by_date = included[0]["attributes"]
          #       if json_data["meta"].present?
          #         latest_inspection_by_date["meta"] = json_data["meta"]
          #       end
          #     end
          # end

        rescue
          Rails.logger.error("ERROR Sparkle::Commands::LatestInspection fetching data from #{@url}")
          error = "ERROR: Latest Inspection call failed"
        end

        if error.nil? && http_response.code != 200
          error = "ERROR: Latest Inspection call failed (#{http_response.code})"
        end
        
        data = {latest_inspection: latest_inspection, property_data: property_data, error: error}
        Rails.logger.debug data.inspect
        return data
      end

      private

    end
  end
end
