require 'test_helper'

module Metrics
  module Commands
    class ImportCsvFileTest < ActiveSupport::TestCase
      def setup
        spreadsheet_path = "#{Rails.root}/test/fixtures/files/metrics_update.csv"
        @command = Metrics::Commands::ImportExcelSpreadsheet.new(spreadsheet_path, 'http://localhost:3000')
      end
      
      test "determines if the test file passes" do 
        @command.perform
      end
      

      
    end
  end
end
