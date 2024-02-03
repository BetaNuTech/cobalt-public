require 'httparty'
require 'cgi'

module Bluesky
  module Commands
    class PropertyStats
      include HTTParty

      def initialize(property:, on_date:)
        @property = property
        @on_date = on_date

        if @on_date.nil?
            @url = Settings.druid_prospect_stats_url + "&stats=properties&ids[]=#{@property.code}"
        else
            @url = Settings.druid_prospect_stats_url + "&stats=properties&ids[]=#{@property.code}&date=#{@on_date}"
        end

      end

      def perform
        http_response = nil
        error = nil
        begin
          http_response = HTTParty.get(@url)
          @json_data = http_response.parsed_response
          puts "--- Bluesky: Property Stats Response for #{@property.code} ---"
          puts @json_data

        rescue
          Rails.logger.error("ERROR Bluesky::Commands::PropertyStats fetching data from #{@url}")
          error = "ERROR: Bluesky PropertyStats call failed"
        end

        if error.nil? && http_response.code != 200
          error = "ERROR: Bluesky PropertyStats call failed (#{http_response.code})"
        end
        
        data = {stats: statsForProperty(@json_data, @property.code), error: error}
        Rails.logger.debug data.inspect
        return data
      end

      private

      def statsForProperty(data, propertyCode)
        if data.nil?
            return nil
        end

        propertiesArray = data['Properties']
        if !propertiesArray.nil? && propertiesArray.kind_of?(Array)
          propertiesArray.each do |propertyHash|
            if propertyHash['ID'] == propertyCode
              return propertyHash['Stats']
            end
          end
        end
    
        return nil
      end

    end
  end
end
