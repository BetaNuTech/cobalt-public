module TrmBlueShifts
  module Commands
    class Archive

      def initialize(trm_blue_shift_id, archived_status, current_user)
        @trm_blue_shift = TrmBlueShift.find(trm_blue_shift_id)
        @archived_status = archived_status
        @current_user = current_user
      end

      def perform
        reset_trm_blue_shift_requirement = 
          Properties::Commands::ResetTrmBlueShiftRequirement.new(@trm_blue_shift.property.id)
        reset_trm_blue_shift_requirement.perform
        @trm_blue_shift.reload

        if !@trm_blue_shift.archived
          @trm_blue_shift.initial_archived_status = @archived_status

          # Check for valid metric today, otherwise may be system date and wrong day (next day)
          todays_metric = Metric.where(property: @trm_blue_shift.property, date: Date.today).where(main_metrics_received: true).first
          if todays_metric.nil?
            latest_metric = Metric.where(property: @trm_blue_shift.property).where(main_metrics_received: true).order("date DESC").first
            if latest_metric.nil?
              @trm_blue_shift.initial_archived_date = Date.today
            else
              @trm_blue_shift.initial_archived_date = latest_metric.date
            end
          else 
            @trm_blue_shift.initial_archived_date = Date.today
          end
        end
      
        # If overridding, record it
        if @trm_blue_shift.archived && !@current_user.nil? && @trm_blue_shift.initial_archived_status != @archived_status
          @trm_blue_shift.archive_edit_user = @current_user
          @trm_blue_shift.archive_edit_date = Date.today
        end
          
        @trm_blue_shift.archived = true
        @trm_blue_shift.archived_status = @archived_status
        @trm_blue_shift.save!   
        
        set_property_trm_blue_shift_status(@trm_blue_shift.property)
      end
      
      private
      def set_property_trm_blue_shift_status(property)
        check_trm_blue_shift_requirement = Properties::Commands::CheckTrmBlueShiftRequirement.new(property.id)
        if check_trm_blue_shift_requirement.perform
          property.trm_blue_shift_status = "required"
          property.save!
        end
      end

    end
  end
end