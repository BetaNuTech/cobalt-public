class PropertyChartsController < ApplicationController
  before_action :set_metrics, only: [:show]
  before_action :set_charts_data, only: [:show]

  # GET /property_charts/:code
  # GET /property_charts/:code.json
  def show
    respond_to do |format|
      format.html
      format.json { render json: @charts_data.to_json }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_metrics
      @property = Property.where(code: params[:code]).first
      # all metrics, for each metric attribute, for the given property
      # @metric = Metric.where(property: @property).order("date DESC").first
      metricId = params[:metricId]
      @date = params[:property_charts_date]
      if metricId
        @metric = Metric.find(params[:metricId])
        @date = @metric.date
        puts "Metric ID: #{metricId}"
      elsif @date
        @metric = Metric.where(property: @property, date: @date).first
        puts "Date: #{@date}"
      end

      @full_size = params[:full_size] == "1"

      @metric_attributes = MetricChartData.valid_metric_attributes().sort

      $custom_attributes = params[:custom_attributes]
      if $custom_attributes == 'trending_all_graphs'
        # trending_average_daily
        # trending_next_month
        @metric_attributes = ['trending_average_daily', 'trending_next_month']
      elsif $custom_attributes == 'occupancy_all_graphs'
        # occupancy_average_daily
        # occupancy_budgeted_economic
        # occupancy_average_daily_30_days_ago
        @metric_attributes = ['occupancy_average_daily', 'occupancy_budgeted_economic', 'occupancy_average_daily_30_days_ago']
      elsif $custom_attributes == 'average_rents_all_graphs'
        @metric_attributes = [
          'average_market_rent', 
          'average_rent_weighted_per_unit_specials', 
          'average_rents_net_effective', 
          'average_rents_net_effective_budgeted', 
          'average_rent_delta_percent', 
          'average_rent_year_over_year_without_vacancy', 
          'average_rent_year_over_year_with_vacancy',
          'average_rent_1bed_net_effective',
          'average_rent_1bed_new_leases',
          'average_rent_1bed_renewal_leases',
          'average_rent_2bed_net_effective',
          'average_rent_2bed_new_leases',
          'average_rent_2bed_renewal_leases',
          'average_rent_3bed_net_effective',
          'average_rent_3bed_new_leases',
          'average_rent_3bed_renewal_leases',
          'average_rent_4bed_net_effective',
          'average_rent_4bed_new_leases',
          'average_rent_4bed_renewal_leases']
      elsif $custom_attributes == 'basis_all_graphs'
        # basis
        # basis_year_to_date
        @metric_attributes = ['basis', 'basis_year_to_date']
      elsif $custom_attributes == 'expenses_all_graphs'
        # expenses_percentage_of_past_month
        # expenses_percentage_of_budget
        @metric_attributes = ['expenses_percentage_of_past_month', 'expenses_percentage_of_budget']
      elsif $custom_attributes == 'renewals_all_graphs'
        # renewals_unknown
        # renewals_number_renewed
        # renewals_percentage_renewed
        # renewals_residents_month_to_month
        @metric_attributes = ['renewals_unknown', 'renewals_number_renewed', 'renewals_percentage_renewed', 'renewals_residents_month_to_month']
      elsif $custom_attributes == 'collections_all_graphs'
        # collections_current_status_residents_with_last_month_balance
        # collections_unwritten_off_balances
        # collections_percentage_recurring_charges_collected
        # collections_current_status_residents_with_current_month_balance
        # collections_number_of_eviction_residents
        @metric_attributes = ['collections_current_status_residents_with_last_month_balance', 'collections_unwritten_off_balances',
         'collections_percentage_recurring_charges_collected', 'collections_current_status_residents_with_current_month_balance',
         'collections_number_of_eviction_residents']
      elsif $custom_attributes == 'maintenance_all_graphs'
        # maintenance_percentage_ready_over_vacant
        # maintenance_number_not_ready
        # maintenance_turns_completed
        # maintenance_open_wos
        @metric_attributes = ['maintenance_percentage_ready_over_vacant', 'maintenance_number_not_ready',
         'maintenance_turns_completed', 'maintenance_open_wos', 'maintenance_total_open_work_orders']
      end

    end

    def set_charts_data
      @charts_data = []
      @metric_attributes.each do |attr| 
        # @charts_data.append(MetricChartData.collect_data(@metric, attr))
        if @full_size
          @charts_data.append("metric_id=#{@metric.id} data_metric=#{attr} property_name=#{@property.code} full_size=1")
          if $custom_attributes == 'trending_all_graphs'
            overlay_attr = 'average_market_rent'
            @overlay_chart_data = "metric_id=#{@metric.id} data_metric=#{overlay_attr} property_name=#{@property.code} full_size=1"
          elsif $custom_attributes == 'maintenance_all_graphs'
            overlay_attr = 'maintenance_vacants_over_nine_days'
            @overlay_chart_data = "metric_id=#{@metric.id} data_metric=#{overlay_attr} property_name=#{@property.code} full_size=1"
            @overlay_chart_data_index_only = 0
          end
        else
          @charts_data.append("metric_id=#{@metric.id} data_metric=#{attr} property_name=#{@property.code}")
        end
      end
    end

end
