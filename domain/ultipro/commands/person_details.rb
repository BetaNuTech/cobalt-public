require 'httparty'
require 'cgi'

module Ultipro
  module Commands
    class PersonDetails
      include HTTParty

      AUTH='ULTIPRO_API_UN_PWD_BASE64'

      def initialize
        @page = 1
        @headers = { 
          "Authorization" => "Basic #{ENV.fetch(AUTH)}",
          "US-Customer-Api-Key" => "YSE2F"          
        }
        @url = "https://service4.ultipro.com/personnel/v1/person-details"
      end

      def queryForPage(page:)
        if @query_date.nil?
          { 
            "per_Page"     => 100,
            "page"         => "#{page}"
          }
        else
          { 
            "per_Page"     => 100,
            "page"         => "#{page}",
            "dateTimeChanged" =>">#{@query_date.strftime("%m-%d-%Y")}"
          }
        end
      end

      def perform
        # REMOVED due to risk of lost data, if not all data is imported each time
        # Find latest updated employee, for only requesting new data
        # latest_updated_employee = Employee.order("ext_person_changed_at DESC").first
        # if latest_updated_employee.present?
        #   @query_date = latest_updated_employee.ext_person_changed_at
        #   puts "Lastest Update Date Found: #{@query_date.strftime("%m-%d-%Y")}"
        # end
        @query = queryForPage(page: @page)

        paging = true
        
        @total_imported = 0

        while (paging)
          sleep 1
          result = get_person_details()

          if result[:errors].present?
            puts result[:errors]
            return
          end
      
          # Read in Details to Database
          details_array = result[:json_data]
          if details_array.present? && details_array.kind_of?(Array)
            details_array.each do |detail|
              import_person_detail(detail: detail)
            end

            if details_array.count == 0
              paging = false
            else
              @page += 1
              @query = queryForPage(page: @page)
            end
          else  
            paging = false
          end
        end

        puts "Total Person Detail Imports: #{@total_imported}"

        # Data Import Record
        new_record = DataImportRecord.apiJSON(
          source: DataImportRecordSource::ULTIPRO, 
          data_date: nil, 
          data_datetime: nil, 
          title: DataImportRecordUltproJSONTitle::PersonnelPersonDetails)
        new_record.data_imported = @total_imported > 0
        new_record.save!
        new_record.sendNoficationToSlack()
      end

      private

      def import_person_detail(detail: )
        employee_id = detail["employeeId"]
        if employee_id.nil?
          return
        end

        # Create or Find Employee
        employee = Employee.where(employee_id: employee_id).first_or_initialize

        employee.ext_created_at = detail["datetimeCreated"].present? ? DateTime.parse(detail["datetimeCreated"]) : nil
        employee.ext_person_changed_at = detail["datetimeChanged"].present? ? DateTime.parse(detail["datetimeChanged"]) : nil
        employee.date_of_birth = detail["dateOfBirth"].present? ? DateTime.parse(detail["dateOfBirth"]) : nil

        # Required to save job
        employee.first_name = detail["firstName"]
        employee.last_name = detail["lastName"]
        employee.map_to_workable_name()

        begin
          employee.save!
          @total_imported += 1
        rescue Exception => e
          puts "Ultipro::Commands::PersonDetails - SAVE ERROR: #{e.message}"
        end
      end


      def get_person_details
        http_response = nil
        error = nil
        begin
          http_response = HTTParty.get(@url, :query => @query, :headers => @headers)
          json_data = http_response.parsed_response
        rescue
          message = "ERROR Ultipro::Commands::PersonDetails fetching data from #{@url}"
          Rails.logger.error(message)
          puts message
          error = message
        end

        if error.nil? && http_response.code != 200
          message = "ERROR: Ultipro person-details API Jobs call failed (#{http_response.code})"
          Rails.logger.error(message)
          puts message
          error = message
        end

        puts "----------------------------------------"
        if error.nil?
          puts "Ultipro PersonDetails: Jobs Call SUCCESSFUL (Page: #{@page})"
        else 
          puts "Ultipro PersonDetails: Jobs Call FAILED (Page: #{@page})"
        end
        puts "----------------------------------------"
        
        data = {json_data: json_data, error: error}
        # Rails.logger.debug data.inspect
        return data
      end

    end
  end
end
