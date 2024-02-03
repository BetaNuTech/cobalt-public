require 'logger'

module Properties
  module Commands
    class CheckTrmBlueShiftRequirement
      def initialize(property_id)
        @property = Property.find(property_id)
      end

      def perform
        logger = Logger.new(STDOUT)

        if @property == nil || @property.type == 'Team' || @property.code == Property.portfolio_code()
           # @logger.debug("CheckBlueShiftRequirement: property is nil")
           return false
        end

        # Find latest valid date
        valid_date = Date.today
        todays_metric = Metric.where(property: @property, date: valid_date).where(main_metrics_received: true).first
        if todays_metric.nil?
          latest_metric = Metric.where(property: @property).order("date DESC").where(main_metrics_received: true).first
          if latest_metric.nil?
            return false
          else
            valid_date = latest_metric.date
          end

          trm_blueshift_form_needed = Metric.trm_blueshift_form_needed?([latest_metric])
          if trm_blueshift_form_needed
            logger.debug("CheckTrmBlueShiftRequirement:latest_metric.trm_blueshift_form_needed? - true")
          end

          return trm_blueshift_form_needed
        end

        trm_blueshift_form_needed = Metric.trm_blueshift_form_needed?([todays_metric])
        if trm_blueshift_form_needed
          logger.debug("CheckTrmBlueShiftRequirement:todays_metric.trm_blueshift_form_needed? - true")
        end

        return trm_blueshift_form_needed
      end


    end
  end
end
