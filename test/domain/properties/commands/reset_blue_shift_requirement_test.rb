require 'test_helper'

module Properties
  module Commands
    class ResetBlueShiftRequirementTest < ActiveSupport::TestCase
      def setup
        
        def setup 
          @property = properties(:home)
          @command = Properties::Commands::ResetBlueShiftRequirement.new(@property.id)
        end
        
        test "assigns blue_shift_status of not_required if metrics are now good" do
          @property.blue_shift_status = "pending"
          @property.current_blue_shift = blue_shifts(:default)
          @property.code = "walnut"
          @property.save!
   
          @command.perform
          
          @property.reload
          assert_equal "not_required", @property.blue_shift_status
        end
              
        test "resets current_blue_shift if metrics are now good" do
          @property = properties(:home)
          @property.blue_shift_status = "pending"
          @property.current_blue_shift = blue_shifts(:default)
          @property.code = "walnut"
          @property.save!
   
          @command.perform
          
          @property.reload
          assert_equal "not_required", @property.blue_shift_status
        end
        
        
        test "reset user_properties if metrics are now good" do
          @property = properties(:home)
          @property.blue_shift_status = "pending"
          @property.current_blue_shift = blue_shifts(:default)
          @property.code = "walnut"
          @property.save!
   
          @command.perform
          
          @property.reload
          assert_nil @property.current_blue_shift 
        end
      end
    end
  end
end
