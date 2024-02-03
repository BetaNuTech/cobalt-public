require 'test_helper'

module BlueShifts
  module Commands
    class ArchiveTest < ActiveSupport::TestCase
      def setup 
        @blue_shift = blue_shifts(:default)
        @command = BlueShifts::Commands::Archive.new(@blue_shift.id, "success", "", nil)
      end
      
      test "flips archive flag" do 
        @command.perform
        @blue_shift.reload
        assert_equal true, @blue_shift.archived
      end
      
      test "sets archived status" do
        @command.perform
        @blue_shift.reload
        assert_equal "success", @blue_shift.archived_status        
      end
      
      test "resets blue shift status" do
        reset = mock()
        Properties::Commands::ResetBlueShiftRequirement.expects(:new)
          .with(@blue_shift.property.id).returns(reset)
        reset.expects(:perform)
        
        @command.perform   
      end
      
      # test "sets blue shift status to require if latest metric needs blue shift" do
      #   latest_metric = Metric.where(property: @blue_shift.property)
      #     .order("date DESC").first
          
      #   latest_metric.basis = 4
      #   latest_metric.save!
        
      #   @command.perform
      #   @blue_shift.reload
      #   assert_equal "required", @blue_shift.property.blue_shift_status        
      # end
    end
  end
end
        
