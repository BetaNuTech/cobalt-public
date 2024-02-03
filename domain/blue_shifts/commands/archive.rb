module BlueShifts
  module Commands
    class Archive

      def initialize(blue_shift_id, archived_status, failure_reasons, current_user)
        @blue_shift = BlueShift.find(blue_shift_id)
        @archived_status = archived_status
        @failure_reasons = failure_reasons
        @current_user = current_user
      end

      def perform
        reset_blue_shift_requirement = 
          Properties::Commands::ResetBlueShiftRequirement.new(@blue_shift.property.id)
        reset_blue_shift_requirement.perform
        @blue_shift.reload

        if !@blue_shift.archived
          @blue_shift.initial_archived_status = @archived_status

          # Check for valid metric today, otherwise may be system date and wrong day (next day)
          todays_metric = Metric.where(property: @blue_shift.property, date: Date.today).where(main_metrics_received: true).first
          if todays_metric.nil?
            latest_metric = Metric.where(property: @blue_shift.property).where(main_metrics_received: true).order("date DESC").first
            if latest_metric.nil?
              @blue_shift.initial_archived_date = Date.today
            else
              @blue_shift.initial_archived_date = latest_metric.date
            end
          else 
            @blue_shift.initial_archived_date = Date.today
          end
        end
      
        # If overridding, record it
        if @blue_shift.archived && !@current_user.nil? && @blue_shift.initial_archived_status != @archived_status
          @blue_shift.archive_edit_user = @current_user
          @blue_shift.archive_edit_date = Date.today
        end
          
        @blue_shift.archived = true
        @blue_shift.archived_status = @archived_status
        @blue_shift.archived_failure_reasons = @failure_reasons
        @blue_shift.save!   
        
        set_property_blue_shift_status(@blue_shift.property)
      end
      
      private
      def set_property_blue_shift_status(property)
        # latest_metric = Metric.where(property: @blue_shift.property)
        #   .order("date DESC").first
          
        # if latest_metric.blue_shift_form_needed?
        #   property.blue_shift_status = "required"
        #   property.save!
        # end
        check_blue_shift_requirement = Properties::Commands::CheckBlueShiftRequirement.new(property.id)
        if check_blue_shift_requirement.perform
          property.blue_shift_status = "required"
          property.save!
        end
      end

    end
  end
end