module Properties
  module Commands
    class UpdateBlueShiftStatus

      def perform
        Property.all.each do |property|
          next if property.blue_shift_status != "pending"
          blue_shift = property.current_blue_shift

          if blue_shift.present? and 
            blue_shift.latest_fix_by_date < Time.now.to_date
            
            unless blue_shift_required?(property)
              reset_blue_shift_requirement = 
                Properties::Commands::ResetBlueShiftRequirement.new(property.id)
              reset_blue_shift_requirement.perform      
            end
            
          end
        end
      end
      
      private
      def blue_shift_required?(property)
        # metric = Metric.where(property: property).order("date DESC").first
        # return metric.blue_shift_form_needed?

        check_blue_shift_requirement = Properties::Commands::CheckBlueShiftRequirement.new(property.id)
        return check_blue_shift_requirement.perform
      end

    end

  end
end
