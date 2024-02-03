module Properties
  module Commands
    class UpdateTrmBlueShiftStatus

      def perform
        Property.all.each do |property|
          next if property.trm_blue_shift_status != "pending"
          trm_blue_shift = property.current_trm_blue_shift

          if trm_blue_shift.present? and 
            trm_blue_shift.latest_fix_by_date < Time.now.to_date
            
            unless trm_blue_shift_required?(property)
              reset_trm_blue_shift_requirement = 
                Properties::Commands::ResetTrmBlueShiftRequirement.new(property.id)
              reset_trm_blue_shift_requirement.perform      
            end
            
          end
        end
      end
      
      private
      def trm_blue_shift_required?(property)
        check_trm_blue_shift_requirement = Properties::Commands::CheckTrmBlueShiftRequirement.new(property.id)
        return check_trm_blue_shift_requirement.perform
      end

    end

  end
end
