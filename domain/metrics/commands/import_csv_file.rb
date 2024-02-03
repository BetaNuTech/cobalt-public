require 'roo'

module Metrics
  module Commands
    class ImportCsvFile
      def initialize(csv_file_path)
        @csv_file_path = csv_file_path
      end
      
      def perform
        file_extension = File.extname(@csv_file_path)
        file_extension[0] = '' # remove the dot
        
        if file_extension.blank?
          file_extension = "csv"
        end
        
        csv = Roo::CSV.new(@csv_file_path,
          extension: file_extension)
          
        ActiveRecord::Base.transaction do
          import(csv)
        end
      end
      
      private
      def import(csv)
        # date, property_code, data...
        ref_row = csv.row(1)
        if ref_row[0].strip != 'date' || ref_row[1].strip != 'property_code'
          return
        end

        for i in (2..csv.last_row)
          row = csv.row(i)
          # date = get_date(row)
          
          # property = get_property(row)
          # if property == nil
          #   next
          # end
          # metric = get_existing_metric(property, date)
          # if metric == nil
          #   next
          # end
          
          update_values_for_metric = Metrics::Commands::UpdateValuesForMetric.new(ref_row, row)
          update_values_for_metric.perform
        end
      end

      def remove_s3_file
        
      end
      
    end
  end
end
