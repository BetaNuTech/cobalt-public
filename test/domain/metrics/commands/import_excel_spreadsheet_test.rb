require 'test_helper'

module Metrics
  module Commands
    class ImportExcelSpreadsheetTest < ActiveSupport::TestCase
      def setup
        spreadsheet_path = "#{Rails.root}/test/fixtures/files/daily_report.xlsx"
        @command = Metrics::Commands::ImportExcelSpreadsheet.new(spreadsheet_path, 'http://localhost:3000')
      end
      
      test "determines file extension if not specified" do 
        spreadsheet_path = "#{Rails.root}/test/fixtures/files/daily_report"
        @command = Metrics::Commands::ImportExcelSpreadsheet.new(spreadsheet_path, 'http://localhost:3000')
        @command.perform
      end
      
      test "creates properties" do 
        assert_difference "Property.count", 29 do 
          @command.perform
        end
      end
      
      test "gets properties" do 
        Property.create!(code: "Portfolio")
        assert_difference "Property.count", 28 do 
          @command.perform
        end
      end
      
      # test "assigns blue_shift_status of required" do 
      #   Property.create!(code: "Portfolio")
      #   assert_difference "Property.where(blue_shift_status: 'required').count", 27 do 
      #     @command.perform
      #   end
      # end
      
      test "resets property current_blue_shift if required" do 
        Property.create!(code: "Portfolio")
        property = properties(:home)
        property.blue_shift_status = "not_required"
        property.maint_blue_shift_status = "not_required"        
        property.code = "paddock"
        property.save!
        
        @command.perform
        
        property.reload
        
        assert_nil property.current_blue_shift
      end
      
      # test "does not assign blue_shift_status of required if pending" do
      #   property = properties(:home)
      #   property.blue_shift_status = "pending"
      #   property.current_blue_shift = blue_shifts(:default)
      #   property.code = "paddock"
      #   property.save!
        
      #   assert_difference "Property.where(blue_shift_status: 'required').count", 26 do 
      #     @command.perform
      #   end
      # end
      
      # test "does not reset current_blue_shift if already pending" do
      #   property = properties(:home)
      #   property.blue_shift_status = "pending"
      #   property.current_blue_shift = blue_shifts(:default)
      #   property.code = "paddock"
      #   property.save!
        
      #   @command.perform
        
      #   property.reload
      #   assert_equal blue_shifts(:default), property.current_blue_shift
  
      # end    
      
      # TODO: WHy does this fail, before code is reached?
      # test "resets blue_shift requirement if metrics are now good" do
      #   property = properties(:home)
      #   property.blue_shift_status = "required"
      #   property.current_blue_shift = nil
      #   property.code = "walnut"
      #   property.save!
        
      #   reset = mock()
      #   Properties::Commands::ResetBlueShiftRequirement.expects(:new)
      #     .with(property.id).returns(reset)
      #   reset.expects(:perform)
 
      #   @command.perform
      # end
      
      
      test "archives current blue_shift if metrics are now good" do
        property = properties(:home)
        property.blue_shift_status = "pending"
        property.maint_blue_shift_status = "not_required"        
        property.current_blue_shift = blue_shifts(:default)
        property.code = "walnut"
        property.save!
        
        archive = mock()
        BlueShifts::Commands::Archive.expects(:new)
          .with(property.current_blue_shift.id, "success", "", nil).returns(archive)
        archive.expects(:perform)
 
        @command.perform
      end
      
      # test "sends alert if blue shift is not_required and is now required" do
      #   send_blue_shift_slack_message = mock()
      #   Alerts::Commands::SendBlueShiftSlackMessage.expects(:new)
      #     .returns(send_blue_shift_slack_message)
      #   Job.expects(:create).at_least_once # For other slack messages
      #   Job.expects(:create).with(send_blue_shift_slack_message)
        
      #   property = properties(:home)
      #   property.blue_shift_status = "not_required"
      #   property.code = "paddock"
      #   property.slack_channel = "#test"
      #   property.save!

      #   @command.perform

      # end
      
      # test "sends alert if blue shift is required and is still required" do
      #   send_blue_shift_slack_message = mock()
      #   Alerts::Commands::SendBlueShiftSlackMessage.expects(:new)
      #     .returns(send_blue_shift_slack_message)
      #   Job.expects(:create).at_least_once # For other slack messages
      #   Job.expects(:create).with(send_blue_shift_slack_message)
        
      #   property = properties(:home)
      #   property.blue_shift_status = "required"
      #   property.code = "paddock"
      #   property.slack_channel = "#test"
      #   property.save!

      #   @command.perform

      # end
      
      test "do not send alert if blue shift is pending" do
        Alerts::Commands::SendBlueShiftSlackMessage.expects(:new).never
        
        property = properties(:home)
        property.blue_shift_status = "pending"
        property.maint_blue_shift_status = "not_required"        
        property.current_blue_shift =  blue_shifts(:default)
        property.code = "paddock"
        property.slack_channel = "#test"
        property.save!

        @command.perform

      end
      
      test "do not send alert if blue shift if metrics are good" do
        Alerts::Commands::SendBlueShiftSlackMessage.expects(:new).never
        
        property = properties(:home)
        property.blue_shift_status = "not_required"
        property.maint_blue_shift_status = "not_required"
        property.code = "walnut"
        property.slack_channel = "#test"
        property.save!

        @command.perform
      end
      
    
      test "imports all metrics" do 
        assert_difference "Metric.count", 29 do 
          @command.perform
        end
      end
      
      test "assigns position of 1 to portfolio metric" do        
        @command.perform
        
        property = Property.where(code: "Portfolio").first
        metric = Metric.where(property: property).first
        
        assert_equal 1, metric.position
      end
      
      test "assigns position of 2 to non-portfolio metrics" do
        @command.perform
        
        property = Property.where(code: "Portfolio").first
        metrics = Metric.where.not(property: property)
        
        metrics.each do |metric|
          assert_equal 2, metric.position      
        end
      end
      
      test "assign fields to portfolio metric" do 
        @command.perform
        
        property = Property.where(code: "Portfolio").first
        metric = Metric.where(property: property).first
        
        assert_equal Date.new(2016,12,15), metric.date
        assert_equal 8171, metric.number_of_units
        assert_equal 93, metric.physical_occupancy
        assert_equal 102, metric.cnoi
        assert_equal 89, metric.trending_average_daily
        assert_equal 92, metric.trending_next_month
        assert_equal 92, metric.occupancy_average_daily
        assert_equal 95, metric.occupancy_budgeted_economic 
        assert_equal 91, metric.occupancy_average_daily_30_days_ago 
        assert_equal 848, metric.average_rents_net_effective 
        assert_equal 839, metric.average_rents_net_effective_budgeted 
        assert_equal 98, metric.basis 
        assert_equal 98, metric.basis_year_to_date 
        assert_equal 51, metric.expenses_percentage_of_past_month 
        assert_equal 68, metric.expenses_percentage_of_budget 
        assert_equal 274, metric.renewals_number_renewed 
        assert_equal 39, metric.renewals_percentage_renewed
        assert_equal 5, metric.collections_current_status_residents_with_last_month_balance
        assert_equal 85, metric.collections_unwritten_off_balances
        assert_equal 94.2, metric.collections_percentage_recurring_charges_collected
        assert_equal 266, metric.collections_current_status_residents_with_current_month_balance
        assert_equal 48, metric.collections_number_of_eviction_residents 
        assert_equal 64, metric.maintenance_percentage_ready_over_vacant 
        assert_equal 165, metric.maintenance_number_not_ready 
        assert_equal 128, metric.maintenance_turns_completed 
        assert_equal 94, metric.maintenance_open_wos 
        assert_equal 312, metric.rolling_30_net_sales 
        assert_equal 111, metric.rolling_10_net_sales 
      end
      
      test "assign fields to a non-portfolio metric" do 
        @command.perform
        
        property = Property.where(code: "gulf").first
        metric = Metric.where(property: property).first
        
        assert_equal Date.new(2016,12,15), metric.date
        assert_equal 200, metric.number_of_units
        assert_equal 89, metric.physical_occupancy
        assert_equal 99, metric.cnoi
        assert_equal 89, metric.trending_average_daily
        assert_equal 91, metric.trending_next_month
        assert_equal 88, metric.occupancy_average_daily
        assert_equal 95, metric.occupancy_budgeted_economic 
        assert_equal 90, metric.occupancy_average_daily_30_days_ago 
        assert_equal 1100, metric.average_rents_net_effective 
        assert_equal 1097, metric.average_rents_net_effective_budgeted 
        assert_equal 93, metric.basis 
        assert_equal 96, metric.basis_year_to_date 
        assert_equal 51, metric.expenses_percentage_of_past_month 
        assert_equal 49, metric.expenses_percentage_of_budget 
        assert_equal 5, metric.renewals_number_renewed 
        assert_equal 27, metric.renewals_percentage_renewed
        assert_equal 1, metric.collections_current_status_residents_with_last_month_balance
        assert_equal 0, metric.collections_unwritten_off_balances
        assert_equal BigDecimal(98.2,3), BigDecimal(metric.collections_percentage_recurring_charges_collected, 3)
        assert_equal 2, metric.collections_current_status_residents_with_current_month_balance
        assert_equal 0, metric.collections_number_of_eviction_residents 
        assert_equal 52, metric.maintenance_percentage_ready_over_vacant 
        assert_equal 9, metric.maintenance_number_not_ready 
        assert_equal 5, metric.maintenance_turns_completed 
        assert_equal 5, metric.maintenance_open_wos 
        assert_equal 7, metric.rolling_30_net_sales 
        assert_equal 3, metric.rolling_10_net_sales 
      end
      
      test "does not import any metrics if there is an exception" do 
        spreadsheet_path = "#{Rails.root}/test/fixtures/files/daily_report_bad.xlsx"
        @command = Metrics::Commands::ImportExcelSpreadsheet.new(spreadsheet_path, 'http://localhost:3000')
        
        assert_no_difference "Metric.count" do 
          begin 
            @command.perform
          rescue
          end
        end
      end
      
      test "do not duplicate metrics when import uses the same date" do 
        @command.perform
        assert_difference "Metric.count", 0 do 
          @command.perform
        end
      end
      
      test "updates data when metrics are imported for existing date" do 
        BlueShift.delete_all
        MaintBlueShift.delete_all
        Metric.delete_all
        @command.perform
        metric1 = Metric.all[1]
        metric2 = Metric.all[2]
        metric3 = Metric.all[3]
        
        expected_basis = metric1.basis
        expected_cnoi = metric2.cnoi
        expected_maintenance_number_not_ready = metric3.maintenance_number_not_ready
        
        metric1.basis = 87
        metric2.cnoi = 23
        metric3.maintenance_number_not_ready = 8.6
        
        metric1.save!
        metric2.save!
        metric3.save!
        
        @command.perform
        
        metric1.reload
        metric2.reload
        metric3.reload
        
        assert_equal expected_basis, metric1.basis
        assert_equal expected_cnoi, metric2.cnoi
        assert_equal expected_maintenance_number_not_ready, metric3.maintenance_number_not_ready
    
      end
      
    end
  end
end
