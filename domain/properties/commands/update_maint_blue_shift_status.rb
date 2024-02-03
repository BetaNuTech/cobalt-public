module Properties
  module Commands
    class UpdateMaintBlueShiftStatus
      
      def perform
        Property.all.each do |property|
          next if property.maint_blue_shift_status != "pending"
          blue_shift = property.current_maint_blue_shift

          if blue_shift.present? and 
            blue_shift.latest_fix_by_date < Time.now.to_date
            
            unless maint_blue_shift_required?(property)
              reset_maint_blue_shift_requirement = 
                Properties::Commands::ResetMaintBlueShiftRequirement.new(property.id)
              reset_maint_blue_shift_requirement.perform      
            end
            
          end
        end
      end
      
      private
      def maint_blue_shift_required?(property)
        # metric = Metric.where(property: property).order("date DESC").first
        # return metric.blue_shift_form_needed?

        check_maint_blue_shift_requirement = Properties::Commands::CheckMaintBlueShiftRequirement.new(property.id)
        return check_maint_blue_shift_requirement.perform
      end

    end
  end
end
