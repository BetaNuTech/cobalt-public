require 'logger'

module Properties
  module Commands
    class CheckBlueShiftRequirement
      def initialize(property_id)
        @property = Property.find(property_id)
      end

      # Return values:
      # 'not_enough_data'
      # 'required'
      # 'not_required'
      def perform
        if @property == nil || @property.type == 'Team' || @property.code == Property.portfolio_code()
           # @logger.debug("CheckBlueShiftRequirement: property is nil")
           return 'not_required'
        end

        # Find latest valid date, with non-nil values
        valid_date = Date.today
        todays_metric = Metric.where(property: @property, date: valid_date)
                              .where(main_metrics_received: true).first
        if todays_metric.nil?
          latest_metric = Metric.where(property: @property)
                                .where(main_metrics_received: true)
                                .order("date DESC").first                  
          if latest_metric.nil?
            logger.debug("CheckBlueShiftRequirement: - no metric found")
            return 'not_enough_data'
          else
            valid_date = latest_metric.date
          end
        end

        physical_occupancy_result_value = CheckBlueShiftRequirement.blueshift_required_for_physical_occupancy_value?(@property, valid_date)
        trending_average_daily_result_value = CheckBlueShiftRequirement.blueshift_required_for_trending_average_daily_value?(@property, valid_date)
        basis_result_value = CheckBlueShiftRequirement.blueshift_required_for_basis_value?(@property, valid_date)

        if physical_occupancy_result_value.nil? && trending_average_daily_result_value.nil? && basis_result_value.nil?
          return 'not_required'
        elsif physical_occupancy_result_value == -1 && trending_average_daily_result_value == -1 && basis_result_value == -1
          return 'not_enough_data'
        else 
          return 'required'
        end
      end


      # What metrics we care about, based on x_rolling_days and y_consecutive_days
      def self.metrics_for_requirement(property, date, x_rolling_days, y_consecutive_days)
        logger = Logger.new(STDOUT)

        num_of_metrics = x_rolling_days + y_consecutive_days - 1
        if num_of_metrics <= 0
          logger.debug("CheckBlueShiftRequirement:metrics_for_requirement - nil case 1")
          return nil
        end

        if date.nil?
          metrics = Metric.where(property: property)
                          .order("date ASC")
                          .where("date > ?", Date.today - num_of_metrics)
                          .where("date <= ?", Date.today)
                          .where(main_metrics_received: true)
        else
          metrics = Metric.where(property: property)
                          .order("date ASC")
                          .where("date > ?", date - num_of_metrics)
                          .where("date <= ?", date)
                          .where(main_metrics_received: true)
        end
                        
        if metrics.nil? || metrics.count != num_of_metrics
          logger.debug("CheckBlueShiftRequirement:metrics_for_requirement - nil case 2")
          return nil
        end

        return metrics
      end

      # def self.metric_for_requirement(property, date)
      #   if date.nil?
      #     return Metric.where(property: property, date: Date.today).first
      #   else
      #     return Metric.where(property: property, date: date).first
      #   end
      # end

      # Is physical_occupancy trigger the need for a blueshift?  If so, what is the value to track?
      def self.blueshift_required_for_physical_occupancy_value?(property, date)
        logger = Logger.new(STDOUT)

        x_rolling_days = Settings.blueshift_x_rolling_days.to_i
        # y_consecutive_days = Settings.blueshift_y_consecutive_days.to_i
        y_consecutive_days = 1

        metrics = CheckBlueShiftRequirement.metrics_for_requirement(property, date, x_rolling_days, y_consecutive_days)
        if metrics.nil?
          logger.debug("CheckBlueShiftRequirement:blueshift_required_for_physical_occupancy_value - not enough info - case 1")
          return -1
        end

        y = 0
        latest_metric = metrics.last
        consecutive_results = []
        while y < y_consecutive_days
          start_index = y
          end_index = y + x_rolling_days - 1 

          average = Metric.average_physical_occupancy(metrics[start_index..end_index])
          result = average < Metric.blue_shift_threshold_for_physical_occupancy(latest_metric) ? true : false
          consecutive_results << result

          y += 1
        end

        if consecutive_results.all? {|x| x == true}
          # Latest metric required to be in red
          if latest_metric.physical_occupancy.present? && latest_metric.physical_occupancy >= Metric.blue_shift_threshold_for_physical_occupancy(latest_metric)
            logger.debug("CheckBlueShiftRequirement:blueshift_required_for_physical_occupancy_value - nil case 2")
            return nil
          else
            # Both rolling average, and current, below threshold.  Blueshift required.
            logger.debug("CheckBlueShiftRequirement.blueshift_required_for_physical_occupancy_value?: average = #{average}, latest = #{latest_metric.physical_occupancy} property = #{property.code}")
            # return latest as trigger value          
            return latest_metric.physical_occupancy
          end
        end

        logger.debug("CheckBlueShiftRequirement:blueshift_required_for_physical_occupancy_value - nil case 3")
        return nil
      end

      def self.blueshift_required_for_trending_average_daily_value?(property, date)
        logger = Logger.new(STDOUT)

        x_rolling_days = Settings.blueshift_x_rolling_days.to_i
        # y_consecutive_days = Settings.blueshift_y_consecutive_days.to_i
        y_consecutive_days = 1

        metrics = CheckBlueShiftRequirement.metrics_for_requirement(property, date, x_rolling_days, y_consecutive_days)
        if metrics.nil?
          logger.debug("CheckBlueShiftRequirement:blueshift_required_for_trending_average_daily_value - non enough info - case 1")
          return -1
        end

        y = 0
        latest_metric = metrics.last
        consecutive_results = []
        while y < y_consecutive_days
          start_index = y
          end_index = y + x_rolling_days - 1 

          average = Metric.average_trending_average_daily(metrics[start_index..end_index])
          result = average < Metric.blue_shift_threshold_for_trending_average_daily(latest_metric) ? true : false
          consecutive_results << result

          y += 1
        end

        if consecutive_results.all? {|x| x == true}
          # Latest metric required to be in red
          if latest_metric.trending_average_daily.present? && latest_metric.trending_average_daily >= Metric.blue_shift_threshold_for_trending_average_daily(latest_metric)
            logger.debug("CheckBlueShiftRequirement:blueshift_required_for_trending_average_daily_value - nil case 2")
            return nil
          else
            # Both rolling average, and current, below threshold.  Blueshift required.
            logger.debug("CheckBlueShiftRequirement.blueshift_required_for_trending_average_daily_value?: average = #{average}, latest = #{latest_metric.trending_average_daily} property = #{property.code}")
            # return latest as trigger value
            return latest_metric.trending_average_daily
          end
        end

        logger.debug("CheckBlueShiftRequirement:blueshift_required_for_trending_average_daily_value - nil case 3")
        return nil
      end

      def self.blueshift_required_for_basis_value?(property, date)
        logger = Logger.new(STDOUT)
        
        metrics_desc = CheckBlueShiftRequirement.same_month_metrics_ordered(property, date) # ordered by date, newest to oldest, all for current month only
        if metrics_desc.nil? || metrics_desc.count == 0
          logger.debug("CheckBlueShiftRequirement:blueshift_required_for_basis_value? - non enough inf - case 1")
          return -1
        end

        # Change to ASC order
        metrics = metrics_desc.reverse

        # Latest metric required to be in red
        current_metric = metrics.last
        if current_metric.basis.present? && current_metric.basis >= Metric.blue_shift_threshold_for_basis
          logger.debug("CheckBlueShiftRequirement:blueshift_required_for_basis_value? - nil case 2")
          return nil
        end

        trigger_x_y_value = CheckBlueShiftRequirement.basis_trigger_x_y(property, metrics_desc) # looking back from latest metric

        average_rent_2_percent_or_lower_compared_to_the_6th = false
        metric_was_below_threshold_1st_to_6th = false
        metrics.each_with_index do |metric, index|
          if metric.date.mday == 6
            if !metric.average_rent_delta_percent.nil? && !current_metric.average_rent_delta_percent.nil? &&
              current_metric.average_rent_delta_percent - metric.average_rent_delta_percent <= -2.0
              average_rent_below_2_percent_compared_to_the_6th = true
            end
          end

          if metric.date.mday <= 6 && metric.basis.present? && metric.basis < Metric.blue_shift_threshold_for_basis
            metric_was_below_threshold_1st_to_6th = true
          end

          # Check Latest Metric, if between 1st to 6th
          if metric.date.mday == current_metric.date.mday
            if metric.date.mday <= 6
              logger.debug("CheckBlueShiftRequirement.basis_trigger: result_value = #{current_metric.basis}, 1st case, property = #{property.code}")
              return current_metric.basis
            elsif metric.date.mday <= 11
              if metric_was_below_threshold_1st_to_6th
                if !trigger_x_y_value.nil?
                  logger.debug("CheckBlueShiftRequirement.basis_trigger: result_value = #{current_metric.basis}, 2nd case, property = #{property.code}")
                  return current_metric.basis
                else
                  logger.debug("CheckBlueShiftRequirement:blueshift_required_for_basis_value? - nil case 3")
                  return nil
                end
              elsif average_rent_2_percent_or_lower_compared_to_the_6th
                logger.debug("CheckBlueShiftRequirement.basis_trigger: result_value = #{current_metric.basis}, 3rd case, property = #{property.code}")
                return current_metric.basis
              else
                logger.debug("CheckBlueShiftRequirement:blueshift_required_for_basis_value? - nil case 4")
                return nil
              end
            elsif !trigger_x_y_value.nil? && average_rent_2_percent_or_lower_compared_to_the_6th
              logger.debug("CheckBlueShiftRequirement.basis_trigger: result_value = #{current_metric.basis}, 4th case, property = #{property.code}")
              return current_metric.basis
            end
          end

        end

        logger.debug("CheckBlueShiftRequirement:blueshift_required_for_basis_value? - nil case 5")
        return nil
      end

      def self.same_month_metrics_ordered(property, date)

        if date.nil?
          month_of_metrics = Metric.where(property: property)
                                   .where(main_metrics_received: true)
                                   .order("date DESC").first(31)
        else
          month_of_metrics = Metric.where(property: property)
                                   .where(main_metrics_received: true)
                                   .order("date DESC")
                                   .where("date <= ?", date).first(31)
        end


        if month_of_metrics.nil? || month_of_metrics.count == 0
          return nil          
        end

        current_month = month_of_metrics[0].date.mon
        metrics_same_month = month_of_metrics.select { |m| m.date.mon == current_month }

        return metrics_same_month
      end

      # metrics assumed to be descending by date.
      def self.basis_trigger_x_y(property, metrics)
        logger = Logger.new(STDOUT)

        x_rolling_days = Settings.blueshift_x_rolling_days.to_i
        y_consecutive_days = Settings.blueshift_y_consecutive_days.to_i

        num_of_metrics = x_rolling_days + y_consecutive_days - 1
        
        if metrics.count >= num_of_metrics
          y = 0
          consecutive_results = []
          while y < y_consecutive_days
            start_index = y
            end_index = y + x_rolling_days - 1 
  
            average = Metric.average_basis(metrics[start_index..end_index])
            result = average < Metric.blue_shift_threshold_for_basis ? true : false
            consecutive_results << result
  
            y += 1
          end

          if consecutive_results.all? {|x| x == true}
            # return latest average, as trigger value
            # Since metrics are reversed here, it's the 1st rolling average
            start_index = 0
            end_index = x_rolling_days - 1 
            average = Metric.average_basis(metrics[start_index..end_index])
            logger.debug("CheckBlueShiftRequirement.basis_trigger_x_y: average = #{average}, property = #{property.code}")
            return average
          end
        end

        return nil
      end

    end
  end
end
