module Metrics
  module Commands
    class UpdateValuesForMetric
      def initialize(ref_row, row)
        @ref_row = ref_row
        @row = row
      end
      
      def perform
        date = get_date(@row)
        
        property = get_property(@row)
        if property == nil
          return
        end
        metric = get_existing_metric(property, date)
        if metric == nil
          return
        end

        @row.each_with_index do |value, index|
          if index < 2
            next
          end

          decimal_value = get_decimal_from_string(value)

          case @ref_row[index].strip
          when 'number_of_units'
            metric.number_of_units = decimal_value
          when 'physical_occupancy'
            metric.physical_occupancy = decimal_value
          when 'cnoi'
            metric.cnoi = decimal_value
          when 'trending_average_daily'
            metric.trending_average_daily = decimal_value
          when 'trending_next_month'
            metric.trending_next_month = decimal_value
          when 'occupancy_average_daily'
            metric.occupancy_average_daily = decimal_value
          when 'occupancy_budgeted_economic'
            metric.occupancy_budgeted_economic = decimal_value
          when 'occupancy_average_daily_30_days_ago'
            metric.occupancy_average_daily_30_days_ago = decimal_value
          when 'average_rents_net_effective'
            metric.average_rents_net_effective = decimal_value
          when 'average_rents_net_effective_budgeted'
            metric.average_rents_net_effective_budgeted = decimal_value
          when 'basis'
            metric.basis = decimal_value
          when 'basis_year_to_date'
            metric.basis_year_to_date = decimal_value
          when 'expenses_percentage_of_past_month'
            metric.expenses_percentage_of_past_month = decimal_value
          when 'expenses_percentage_of_budget'
            metric.expenses_percentage_of_budget = decimal_value
          when 'renewals_unknown'
            metric.renewals_unknown = decimal_value
          when 'renewals_number_renewed'
            metric.renewals_number_renewed = decimal_value
          when 'renewals_percentage_renewed'
            metric.renewals_percentage_renewed = decimal_value
          when 'collections_current_status_residents_with_last_month_balance'
            metric.collections_current_status_residents_with_last_month_balance = decimal_value
          when 'collections_unwritten_off_balances'
            metric.collections_unwritten_off_balances = decimal_value
          when 'collections_percentage_recurring_charges_collected'
            metric.collections_percentage_recurring_charges_collected = decimal_value
          when 'collections_current_status_residents_with_current_month_balance'
            metric.collections_current_status_residents_with_current_month_balance = decimal_value
          when 'collections_number_of_eviction_residents'
            metric.collections_number_of_eviction_residents = decimal_value
          when 'maintenance_percentage_ready_over_vacant'
            metric.maintenance_percentage_ready_over_vacant = decimal_value
          when 'maintenance_number_not_ready'
            metric.maintenance_number_not_ready = decimal_value
          when 'maintenance_turns_completed'
            metric.maintenance_turns_completed = decimal_value
          when 'maintenance_open_wos'
            metric.maintenance_open_wos = decimal_value
          when 'rolling_30_net_sales'
            metric.rolling_30_net_sales = decimal_value
          when 'rolling_10_net_sales'
            metric.rolling_10_net_sales = decimal_value
          when 'leases_attained'
            metric.leases_attained = decimal_value
          when 'leases_goal'
            metric.leases_goal = decimal_value
          when 'leases_alert_message'
            metric.leases_alert_message = value
          when 'leases_attained_no_monies'
            metric.leases_attained_no_monies = decimal_value
          when 'average_market_rent'
            metric.average_market_rent = decimal_value
          else
            next
          end
        end

        metric.save!
      end

      private


      def get_decimal_from_string(value)
        if value.nil?
          return BigDecimal(0)
        elsif value.is_a? String and value.strip.empty?
          return BigDecimal(0)
        elsif value.is_a? String
          # Remove all non-digit characters, other than '.' and '-'
          value = value.scan(/[\d.-]+/).join
          return value.to_d 
        else
          return BigDecimal(value, 2)
        end
      end

      def get_existing_metric(property, date)
        return Metric.where(property: property, date: date).first
      end
      
      def get_property(row)
        property_code = row[1].strip
        return Property.where(code: property_code).first
      end
      
      def get_date(row)
        return Date.strptime(row[0].strip, "%m/%d/%Y")
      end
      
    end
  end
end
