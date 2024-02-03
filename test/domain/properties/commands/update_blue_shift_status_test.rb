require 'test_helper'

module Properties
  module Commands
    class UpdateBlueShiftStatusTest < ActiveSupport::TestCase
      def setup
        @command = Properties::Commands::UpdateBlueShiftStatus.new
        @blue_shift = blue_shifts(:default)
        @property = @blue_shift.property
        @user_property = user_properties(:default)
        @metric = metrics(:one)
        
        @metric.basis = 100
        @metric.physical_occupancy = 100
        @metric.trending_average_daily = 100
        @metric.save!
        
      end
      

      test "reset blue_shift requirement if latest fix_by has passed" do 
        @blue_shift.pricing_problem_fix_by = Time.now.to_date - 1.day
        @property.blue_shift_status = "pending"
        @property.current_blue_shift = @blue_shift
        @blue_shift.save!(validate: false)
        @property.save!
        
        reset = mock()
        Properties::Commands::ResetBlueShiftRequirement.expects(:new)
          .with(@property.id).returns(reset)
        reset.expects(:perform)
        
        @command.perform
      end
      
      test "do not reset blue_shift requirement if latest fix_by has not passed" do 
        @blue_shift.pricing_problem_fix_by = 1.day.from_now
        @blue_shift.product_problem_fix_by = nil
        @blue_shift.people_problem_fix_by = nil
        
        @property.blue_shift_status = "pending"
        @property.current_blue_shift = @blue_shift
        @blue_shift.save!
        @property.save!
        
        Properties::Commands::ResetBlueShiftRequirement.expects(:new)
          .with(@property.id).never
        
        @command.perform
      end
      
      test "do not reset blue_shift requirement if blue_shift is still required" do 
        @blue_shift.pricing_problem_fix_by = Time.now.to_date
        @property.blue_shift_status = "required"
        @blue_shift.save!
        @property.save!
        
        Properties::Commands::ResetBlueShiftRequirement.expects(:new)
          .with(@property.id).never
        
        @command.perform
      end
      
      test "do not reset blue_shift requirement if no fix_by date (need_help)" do 
        @blue_shift.people_problem_fix_by = nil
        @blue_shift.product_problem_fix_by = nil
        @blue_shift.pricing_problem_fix_by = nil
        @blue_shift.people_problem = false
        @blue_shift.product_problem = false
        @blue_shift.pricing_problem = false
        @blue_shift.need_help = true
        @blue_shift.need_help_with = "blah blah"
        
        @property.blue_shift_status = "pending"
        @property.current_blue_shift = @blue_shift
        @blue_shift.save!
        @property.save!
        
        Properties::Commands::ResetBlueShiftRequirement.expects(:new)
          .with(@property.id).never
        
        @command.perform
      end
      
      test "do not do anything if there are no blueshifts" do 
        @property.blue_shifts.delete_all
        @property.blue_shift_status = "not_required"
        @property.save!
        
        Properties::Commands::ResetBlueShiftRequirement.expects(:new)
          .with(@property.id).never
        
        @command.perform
      end
      
      
      # test "do not reset blue_shift if metrics are still bad" do 
      #   @blue_shift.pricing_problem_fix_by = Time.now.to_date - 1.day
      #   @property.blue_shift_status = "pending"
      #   @property.current_blue_shift = @blue_shift
      #   @blue_shift.save!(validate: false)
      #   @property.save!
        
      #   @metric.basis = 0 
      #   @metric.save!
        
      #   Properties::Commands::ResetBlueShiftRequirement.expects(:new)
      #     .with(@property.id).never
        
      #   @command.perform
      # end
  
    end
  end
end
