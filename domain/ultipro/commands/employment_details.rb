require 'httparty'
require 'cgi'

module Ultipro
  module Commands
    class EmploymentDetails
      include HTTParty

      AUTH='ULTIPRO_API_UN_PWD_BASE64'

      def initialize
        @page = 1
        @headers = { 
          "Authorization" => "Basic #{ENV.fetch(AUTH)}",
          "US-Customer-Api-Key" => "YSE2F"          
        }
        @url = "https://service4.ultipro.com/personnel/v1/employment-details"
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
        # latest_updated_employee = Employee.order("ext_employment_changed_at DESC").first
        # if latest_updated_employee.present?
        #   @query_date = latest_updated_employee.ext_employment_changed_at
        #   puts "Lastest Update Date Found: #{@query_date.strftime("%m-%d-%Y")}"
        # end
        @query = queryForPage(page: @page)

        paging = true

        @total_imported = 0

        while (paging)
          sleep 1
          result = get_employment_details()

          if result[:errors].present?
            puts result[:errors]
            return
          end
      
          # Read in Details to Database
          details_array = result[:json_data]
          if details_array.present? && details_array.kind_of?(Array)
            details_array.each do |detail|
              import_employment_detail(detail: detail)
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

        puts "Total Employment Detail Imports: #{@total_imported}"

        # Data Import Record
        new_record = DataImportRecord.apiJSON(
          source: DataImportRecordSource::ULTIPRO, 
          data_date: nil, 
          data_datetime: nil, 
          title: DataImportRecordUltproJSONTitle::PersonnelEmployeeDetails)
        new_record.data_imported = @total_imported > 0
        new_record.save!
        new_record.sendNoficationToSlack()
      end

      private

      def import_employment_detail(detail: )
        employee_id = detail["employeeID"]
        if employee_id.nil?
          return
        end

        # Find Employee
        employee = Employee.where(employee_id: employee_id).first
        if employee.nil?
          return
        end

        employee.ext_employment_changed_at = detail["datetimeChanged"].present? ? DateTime.parse(detail["datetimeChanged"]) : nil
        employee.date_in_job = detail["dateInJob"].present? ? DateTime.parse(detail["dateInJob"]) : nil
        employee.date_last_worked = detail["dateLastWorked"].present? ? DateTime.parse(detail["dateLastWorked"]) : nil

        begin
          employee.save!
          @total_imported += 1
        rescue Exception => e
          puts "Ultipro::Commands::EmploymentDetails - SAVE ERROR: #{e.message}"
        end
      end


      def get_employment_details
        http_response = nil
        error = nil
        begin
          http_response = HTTParty.get(@url, :query => @query, :headers => @headers)
          json_data = http_response.parsed_response
        rescue
          message = "ERROR Ultipro::Commands::EmploymentDetails fetching data from #{@url}"
          Rails.logger.error(message)
          puts message
          error = message
        end

        if error.nil? && http_response.code != 200
          message = "ERROR: Ultipro employment-details API Jobs call failed (#{http_response.code})"
          Rails.logger.error(message)
          puts message
          error = message
        end

        puts "----------------------------------------"
        if error.nil?
          puts "Ultipro EmploymentDetails: Jobs Call SUCCESSFUL (Page: #{@page})"
        else 
          puts "Ultipro EmploymentDetails: Jobs Call FAILED (Page: #{@page})"
        end
        puts "----------------------------------------"
        
        data = {json_data: json_data, error: error}
        # Rails.logger.debug data.inspect
        return data
      end

    end
  end
end
