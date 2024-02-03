require 'logger'

module Properties
  module Commands
    class CheckMaintBlueShiftRequirement
      
      def initialize(property_id)
        @property = Property.find(property_id)
        
        @logger = Logger.new(STDOUT)
      end

      def perform
        if @property == nil || @property.type == 'Team' || @property.code == Property.portfolio_code()
          # @logger.debug("CheckBlueShiftRequirement: property is nil")
           return false
        end

        # Pull metric for today
        metric = current_metric()
        if metric.nil?
          return false
        end

        # Check if any of the color-coding levels are 4 (red highlight)
        # if metric.maintenance_percentage_ready_over_vacant_level == 4 ||
        #    metric.maintenance_number_not_ready_level == 4 ||
        #    metric.maintenance_open_wos_level == 4

        #    return true
        # end

        return false
      end

      private

      def current_metric
        return Metric.where(property: @property).where(main_metrics_received: true).order("date DESC").first
      end

    end
  end
end
