module Properties
  module Commands
    class ResetMaintBlueShiftRequirement
      
      def initialize(property_id)
        @property = Property.find(property_id)
      end

      def perform
        @property.maint_blue_shift_status = "not_required" 
        @property.current_maint_blue_shift = nil 
        @property.save!
        reset_user_properties(@property)
      end
      
      def reset_user_properties(property)
        UserProperty.where(property: property).each do |user_property|
          user_property.maint_blue_shift_status = "none"
          user_property.save!
        end
      end
    end
  end
end
