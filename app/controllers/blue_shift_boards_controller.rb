class BlueShiftBoardsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  def show
    @property = Property.find(params[:property_id])
    # @blueshift_board_id = params[:id]
    if @property.present?
      # PM
      @property_manager = @property.property_manager_user
      if @property_manager.present?
        @property_manager_start_date = @property_manager.created_at.strftime("%B, %d, %Y")
        @property_manager_name = @property_manager.first_name + ' ' + @property_manager.last_name
      else 
        @property_manager_name = "PM Not Set"
      end

      # Property
      @property_location = "#{@property.city}, #{@property.state}"
      @property_num_of_units = @property.num_of_units.present? ? "#{@property.num_of_units.to_s}" : ""
      
      @latest_metric = Metric.where(property: @property).where(main_metrics_received: true).order("date DESC").first
      if @latest_metric.present?
        # Latest Metrics
        @latest_metric_date = @latest_metric.date.strftime("%m/%d/%Y")
        @latest_metric_occupancy = number_to_percentage(@latest_metric.physical_occupancy, precision: 1, strip_insignificant_zeros: true)
        @latest_metric_trending = number_to_percentage(@latest_metric.trending_average_daily, precision: 1, strip_insignificant_zeros: true)
        @latest_metric_basis = number_to_percentage(@latest_metric.basis, precision: 1, strip_insignificant_zeros: true)
        @latest_metric_occupancy_status = "no_alert"
        @latest_metric_trending_status = "no_alert"
        @latest_metric_basis_status = "no_alert"

        # Latest CNOI
        @latest_metric_cnoi = number_to_percentage(@latest_metric.cnoi, precision: 1, strip_insignificant_zeros: true)
        @latest_metric_cnoi_status = "no_alert"
        if @latest_metric.cnoi_level >= 3
          @latest_metric_cnoi_status = "alert"
        end
      end

      @blueshift = @property.current_blue_shift
      if @blueshift.present? && @latest_metric.present?
        blueshift_metric = @blueshift.metric
        # Blueshift Trigger metrics
        @blueshift_trigger_date = @blueshift.created_at.strftime("%m/%d/%Y")
        @blueshift_trigger_occupancy = number_to_percentage(blueshift_metric.physical_occupancy, precision: 1, strip_insignificant_zeros: true)
        @blueshift_trigger_trending = number_to_percentage(blueshift_metric.trending_average_daily, precision: 1, strip_insignificant_zeros: true)
        @blueshift_trigger_basis = number_to_percentage(blueshift_metric.basis, precision: 1, strip_insignificant_zeros: true)
        @blueshift_trigger_occupancy_status = @blueshift.physical_occupancy_triggered_value.present? ? "alert" : "no_alert"
        @blueshift_trigger_trending_status = @blueshift.trending_average_daily_triggered_value.present? ? "alert" : "no_alert"
        @blueshift_trigger_basis_status = @blueshift.basis_triggered_value.present? ? "alert" : "no_alert"

        # Blueshift Goal Metrics
        success_value = Metric.blue_shift_success_value_for_physical_occupancy(@blueshift, @latest_metric)
        @blueshift_goal_occupancy = number_to_percentage(success_value, precision: 1, strip_insignificant_zeros: true)
        if success_value > @latest_metric.physical_occupancy
          @blueshift_goal_occupancy_offset = number_to_percentage(success_value - @latest_metric.physical_occupancy, precision: 1, strip_insignificant_zeros: true)
          @latest_metric_occupancy_status = "alert"
        end

        success_value = Metric.blue_shift_success_value_for_trending_average_daily(@blueshift, @latest_metric)
        @blueshift_goal_trending = number_to_percentage(success_value, precision: 1, strip_insignificant_zeros: true)
        if success_value > @latest_metric.trending_average_daily
          @blueshift_goal_trending_offset = number_to_percentage(success_value - @latest_metric.trending_average_daily, precision: 1, strip_insignificant_zeros: true)
          @latest_metric_trending_status = "alert"
        end
        
        success_value = Metric.blue_shift_success_value_for_basis(@blueshift)
        @blueshift_goal_basis = number_to_percentage(success_value, precision: 1, strip_insignificant_zeros: true)
        if success_value > @latest_metric.basis
          @blueshift_goal_basis_offset = number_to_percentage(success_value - @latest_metric.basis, precision: 1, strip_insignificant_zeros: true)
          @latest_metric_basis_status = "alert"
        end

        @blueshift_goal_date = @blueshift.latest_fix_by_date().strftime("%m/%d/%Y")

        # Use latest metric (if available) to calculate days
        date = Date.today
        if @latest_metric.present?
          date = @latest_metric.date.to_date
        end

        # X DAYS BELOW GOAL
        @blueshift_goal_days = (date - @blueshift.created_at.to_date).to_i.to_s + " DAYS"
        @blueShift_goal_days_secondary_text = "BELOW GOAL"
        @blueshift_goal_days_status = "alert"
      else
        # Use latest metric (if available) to calculate days
        date = Date.today
        if @latest_metric.present?
          date = @latest_metric.date.to_date
        end

        # X DAYS ABOVE GOAL
        last_archived_blueshift = BlueShift.where(property: @property, archived: true).where.not(initial_archived_date: nil).order("initial_archived_date DESC").first
        if last_archived_blueshift.present?
          @blueshift_goal_days = (date - last_archived_blueshift.initial_archived_date).to_i.to_s + " DAYS"
        else 
          @blueshift_goal_days = (date - @property.created_at.to_date).to_i.to_s + " DAYS"
        end
        @blueShift_goal_days_secondary_text = "ABOVE GOAL!"
        @blueshift_goal_days_status = "no_alert" 

        # IF BLUESHIFT Required, show triggers for it
        if @property.blue_shift_status == "required" && @latest_metric.present?
          # Blueshift Trigger metrics
          @blueshift_required = true
          @blueshift_trigger_date = Date.today.strftime("%m/%d/%Y")
          @blueshift_trigger_occupancy = number_to_percentage(@latest_metric.physical_occupancy, precision: 1, strip_insignificant_zeros: true)
          @blueshift_trigger_trending = number_to_percentage(@latest_metric.trending_average_daily, precision: 1, strip_insignificant_zeros: true)
          @blueshift_trigger_basis = number_to_percentage(@latest_metric.basis, precision: 1, strip_insignificant_zeros: true)

          temp_blueshift = BlueShift.new()
          temp_blueshift.property = @property
      
          # Set Trigger values
          value = Properties::Commands::CheckBlueShiftRequirement.blueshift_required_for_physical_occupancy_value?(@property, nil)
          temp_blueshift.physical_occupancy_triggered_value = value != -1 ? value : nil
          value = Properties::Commands::CheckBlueShiftRequirement.blueshift_required_for_trending_average_daily_value?(@property, nil)
          temp_blueshift.trending_average_daily_triggered_value = value != -1 ? value : nil
          value = Properties::Commands::CheckBlueShiftRequirement.blueshift_required_for_basis_value?(@property, nil)
          temp_blueshift.basis_triggered_value = value != -1 ? value : nil
          @blueshift_trigger_occupancy_status = temp_blueshift.physical_occupancy_triggered_value.present? ? "alert" : "no_alert"
          @blueshift_trigger_trending_status = temp_blueshift.trending_average_daily_triggered_value.present? ? "alert" : "no_alert"
          @blueshift_trigger_basis_status = temp_blueshift.basis_triggered_value.present? ? "alert" : "no_alert"
        end
      end

      # PEOPLE
      # Bluesky API Data set in properties_controller.rb

      # AGENT Stats
      @people_leasing_stats = create_people_leasing_stats()

      # PEOPLE
      turns_for_property = TurnsForProperty.where(property: @property).order("date DESC").first
      if turns_for_property.present?
        property_code = turns_for_property.property.code
        property_full_name = turns_for_property.property.full_name
        date = turns_for_property.date
        turns = turns_for_property.turned_t9d
        turns_goal = turns_for_property.total_vnr_9days_ago
        percent_of_goal = turns_for_property.percent_turned_t9d
        to_do_turns = turns_for_property.total_vnr

        days_since_goal_reached = 0
        if percent_of_goal < 100
          tfp_last_goal_reached = TurnsForProperty.where(property: turns_for_property.property).where("percent_turned_t9d >= 100").where("date < ?", date).order("date DESC").first
          if !tfp_last_goal_reached.nil?
            days_since_goal_reached = turns_for_property.date - tfp_last_goal_reached.date
          else
            tfp_in_total = TurnsForProperty.where(property: turns_for_property.property).where("date < ?", date).order("date DESC")
            if !tfp_in_total.nil?
              days_since_goal_reached = tfp_in_total.count
            end
          end
        end
        
        @turns_for_property_data = {}

        # Code copied from Alerts::Commands::SendMaintBlueBotTurnsGoalSlackImage
        if percent_of_goal > 100
          @turns_for_property_data[:progress_bar_value] = '100'
          @turns_for_property_data[:status_html] = "<p class=\"status blue_shift_board_color_white\">CONGRATULATIONS!<br /><strong><span class=\"status\">You exceeded your goal!</span></strong></p>"
        elsif percent_of_goal == 100
          @turns_for_property_data[:progress_bar_value] = '100'
          @turns_for_property_data[:status_html] = "<p class=\"status blue_shift_board_color_white\">CONGRATULATIONS!<br /><strong><span class=\"status\">You met your goal!</span></strong></p>"
        else
          @turns_for_property_data[:progress_bar_value] = '%0.f' % percent_of_goal
          @turns_for_property_data[:status_html] = "<p class=\"status blue_shift_board_color_red\">Missed turn goal for <strong><span class=\"status\">#{'%0.f' % days_since_goal_reached}</span></strong> days in a row!</p>"
        end
        @turns_for_property_data[:percent] = '%0.f' % percent_of_goal
        @turns_for_property_data[:metric] = "#{'%0.f' % turns}/#{'%0.f' % turns_goal}"
        @turns_for_property_data[:todo] = "#{'%0.f' % to_do_turns}"
      end

      open_states = ["published"]
      workable_jobs = WorkableJob.where(state: open_states, property: @property)
      @workable_jobs_data = sort_jobs_data(jobs_data(jobs: workable_jobs))
      @recruiting_link = view_context.link_to("Cobalt Recruiting", workable_jobs_path(), class: '', onclick: "show_hud();", data: { turbolinks: false })

      # PRICE
      latest_comp_survey_by_bed_detail = CompSurveyByBedDetail.where(property: @property).order("date DESC").first
      if latest_comp_survey_by_bed_detail.present?
        @latest_comp_survey_date = latest_comp_survey_by_bed_detail.survey_date
      end

      conversions_for_property = ConversionsForAgent.where(agent: @property.code, is_property_data: true).order("date DESC").first
      @property_conversions_data = {}
      @property_conversions_data_alert = false
      if conversions_for_property.present?
        @property_conversions_data = conversions_for_property.property_metrics()
        @property_conversions_data[:prospects_30days] = conversions_for_property.prospects_30days
        if conversions_for_property.prospects_30days.present? && 
           @property_conversions_data[:num_of_leads_needed].present? && 
           conversions_for_property.prospects_30days < @property_conversions_data[:num_of_leads_needed]
          @property_conversions_data_alert = true
        end
      end

      @price_unit_types_data = create_price_unit_types_data()
    end

    first_and_last_days_of_past_twelve_months()
  end

  def create_people_leasing_stats
    leasing_stats = []

    if @latest_metric.nil?
      return leasing_stats
    end

    sales_for_agents = SalesForAgent.where(property: @property, date: @latest_metric.date).order("agent ASC")
    conversions_for_agents = ConversionsForAgent.where(property: @property, date: @latest_metric.date, is_property_data: false).order("agent ASC")

    if sales_for_agents.present?
      # Move Other to bottom, if exists
      sales_for_agents = sales_for_agents.sort_by { |sfa| sfa.agent.downcase == 'other' || sfa.agent_email.nil? || sfa.agent_email == '' ? 1 : 0 }
      for sfa in sales_for_agents do
        if conversions_for_agents.present?
          cfa_index = conversions_for_agents.index {|x| x.agent.downcase == sfa.agent.downcase }
        end

        sales_alert = false
        if sfa.sales.to_i < sfa.goal.to_i 
          sales_alert = true
        end

        past_year_goal_data = find_goals_reached_by(sales_for_agent: sfa)

        if cfa_index.present?
          cfa = conversions_for_agents[cfa_index]
          conversion_alert = people_agent_stats_alert(number(cfa.conversion_30days))
          closing_alert = people_agent_stats_alert(number(cfa.close_30days))
          leasing_stats.push( { 
            "agent" => sfa.agent, 
            "sales_alert" => sales_alert, 
            "conversion_alert" => conversion_alert, 
            "closing_alert" => closing_alert, 
            "sales" => sfa.sales.to_i, 
            "goal" => sfa.goal.to_i, 
            "leads" => cfa.prospects_30days.to_i, 
            "conversion" => number(cfa.conversion_30days), 
            "closing" => number(cfa.close_30days),
            "past_year_goal_data_is_na" => past_year_goal_data[:data_is_na],
            "past_year_goals_reached" => past_year_goal_data[:num_of_goals_reached],
            "past_year_active_months" => past_year_goal_data[:num_of_active_months]
            } )  
        else 
          conversion_alert = false
          closing_alert = false
          leasing_stats.push( { 
            "agent" => sfa.agent, 
            "sales_alert" => sales_alert, 
            "sales" => sfa.sales.to_i, 
            "goal" => sfa.goal.to_i,
            "past_year_goal_data_is_na" => past_year_goal_data[:data_is_na],
            "past_year_goals_reached" => past_year_goal_data[:num_of_goals_reached],
            "past_year_active_months" => past_year_goal_data[:num_of_active_months]
            } )  
        end
      end
    elsif conversions_for_agents.present?
      # Move Other to bottom, if exists
      conversions_for_agents = conversions_for_agents.sort_by { |sfa| sfa.agent.downcase == 'other' ? 1 : 0 }
      for cfa in conversions_for_agents do
        conversion_alert = people_agent_stats_alert(number(cfa.conversion_30days))
        closing_alert = people_agent_stats_alert(number(cfa.close_30days))
        leasing_stats.push( { 
          "agent" => cfa.agent, 
          "conversion_alert" => conversion_alert, 
          "closing_alert" => closing_alert, 
          "leads" => cfa.prospects_30days.to_i, 
          "conversion" => number(cfa.conversion_30days), 
          "closing" => number(cfa.close_30days),
          "past_year_goal_data_is_na" => true,
          "past_year_goals_reached" => 0,
          "past_year_active_months" => 0
        } )  
      end
    end
    puts leasing_stats
    return leasing_stats
  end

  def create_price_unit_types_data
    table_data = []
    rent_change_reason_latest = RentChangeReason.where(property: @property).order("date DESC").first
    if rent_change_reason_latest.present?
      rent_change_reasons = RentChangeReason.where(property: @property, date: rent_change_reason_latest.date).order("unit_type_code ASC")
      table_data = rent_change_reasons.collect do |rcr| 
        # unit_type = "#{number(rcr.unit_type_code)}"
        # unless rcr.num_of_units.nil? || (!rcr.num_of_units.nil? && rcr.num_of_units == 0)
        #   unit_type = "#{number(rcr.unit_type_code)} (#{number(rcr.num_of_units)})"
        # end

        new_effective = '???'
        market_rent = '???'
        last_change_alert = false
        last_change_amount = '$-'
        last_change_date = ''
        # Search for the 1st digit, in unit_type
        bedroom_count = find_first_digit(rcr.unit_type_code)
        if bedroom_count > 0
          detail = AverageRentsBedroomDetail.where(property: @property, date: rent_change_reason_latest.date, num_of_bedrooms: bedroom_count).first
          if detail.present?
            net_effective_avg_rent = money_only_dolars(detail.net_effective_average_rent).to_s
            market_rent = money_only_dolars(detail.market_rent).to_s

            # Find last price change
            detail_last_change = AverageRentsBedroomDetail.where(property: @property, num_of_bedrooms: bedroom_count).where("net_effective_average_rent != ?", detail.net_effective_average_rent).order("date DESC").first
            if detail_last_change.present?
              if detail.net_effective_average_rent < detail_last_change.net_effective_average_rent
                last_change_alert = true
              end
              change_amount = detail.net_effective_average_rent - detail_last_change.net_effective_average_rent
              last_change_amount = money_only_dolars(change_amount).to_s
              last_change_date = detail_last_change.date.strftime("%m/%d/%Y")
            end
          end
        end

        units_vacant_not_leased = rcr.units_vacant_not_leased
        units_vacant_not_leased_alert = false
        if rcr.units_vacant_not_leased.nil?
          units_vacant_not_leased = '?'
        elsif rcr.units_vacant_not_leased > 0
          units_vacant_not_leased_alert = true
        end

        units_on_notice_not_leased = rcr.units_on_notice_not_leased
        units_on_notice_not_leased_alert = false
        if rcr.units_on_notice_not_leased.nil?
          units_on_notice_not_leased = '?'
        elsif rcr.units_on_notice_not_leased > 0
          units_on_notice_not_leased_alert = true
        end

        {
          :unit_type_code => rcr.unit_type_code,
          :num_of_units => rcr.num_of_units.to_i,
          :units_vacant_not_leased => units_vacant_not_leased,
          :units_vacant_not_leased_alert => units_vacant_not_leased_alert,
          :units_on_notice_not_leased => units_on_notice_not_leased,
          :units_on_notice_not_leased_alert => units_on_notice_not_leased_alert,
          :net_effective_avg_rent => net_effective_avg_rent,
          :market_rent => market_rent,
          :last_change_alert => last_change_alert,
          :last_change_amount => last_change_amount,
          :last_change_date => last_change_date
        }
      end
    end

    return table_data
  end

  # Copied from WorkableJobsController
  def jobs_data(jobs:)
    jobs.collect do |j| 
      job_created_at = j.job_created_at
      if j.original_job_created_at.present?
        job_created_at = j.original_job_created_at
      end
      date_opened = job_created_at.to_date.strftime("%m/%d/%y")
      days_open = (DateTime.now - job_created_at.to_datetime).to_i

      title = j.title
      descriptors = []
      if j.is_repost
        descriptors << "repost"
      end
      if j.is_duplicate
        descriptors << "duplicate"
      end
      if j.is_void
        descriptors << "void"
      end
      if j.new_property
        descriptors << "new property"
      end
      if !j.can_post 
        descriptors << "no posting"
      end
      if descriptors.count > 0
        title += " ("
        descriptors.each_with_index do |desc, index|
          if index > 0
            title += ', '
          end
          title += desc
        end
        title += ")"
      end

      if j.last_offer_sent_at.present?
        if j.offer_accepted_at.present?
          time_to_fill = (j.offer_accepted_at.to_datetime - job_created_at.to_datetime).to_i
        end
      end

      if j.hired_at.present?
        time_to_start = (j.hired_at.to_datetime - job_created_at.to_datetime).to_i
      end

      # Team, if exists
      if j.property.team.present?
        team = j.property.team.code
      else 
        team = '' # For sorting purposes
      end

      backend_url = nil
      if j.url.present?
        backend_url = j.url.sub('jobs', 'backend/jobs').concat('/browser')
      end

      code = nil
      type = nil
      if j.property.present?
        code = j.property.code
        type = j.property.type
      end

      {
        :job_created_at => job_created_at,
        # :url => j.url,
        :url => backend_url,
        :team => team,
        :code => code,
        :type => type,
        :title => title,
        :state => j.state,
        :date_opened => date_opened,
        :days_open => days_open,
        :time_to_fill => time_to_fill,
        :time_to_start => time_to_start
      }
    end
  end

  # Copied from WorkableJobsController
  def sort_jobs_data(jobs_data)
    if jobs_data.nil? || jobs_data.empty?
      return []
    end
    
    jobs_data.sort { |a,b| a[:job_created_at] <=> b[:job_created_at] }
  end

  def find_first_digit(string)
    if !string.nil?
      return string[/\d/].to_i
    end

    return 0
  end

  def number(value)
    number_with_precision(value, precision: 0, strip_insignificant_zeros: true)  
  end

  def money(value)
    number_to_currency(value, precision: 2, strip_insignificant_zeros: false)  
  end

  def money_only_dolars(value)
    number_to_currency(value, precision:02, strip_insignificant_zeros: true)  
  end
  
  def percent(value)
    number_to_percentage(value, precision: 0, strip_insignificant_zeros: true)
  end

  def people_agent_stats_alert(percent_data)
    unless percent_data.nil?
      return false if percent_data > number(40)
      return true if percent_data <= number(40)
    end
    return false
  end

  def find_goals_reached_by(sales_for_agent: )
    num_of_goals_reached = 0
    num_of_active_months = 0
    data_is_na = false

    puts "email: " + sales_for_agent.agent_email
    if sales_for_agent.agent.downcase == 'other' || sales_for_agent.agent_email.nil? || sales_for_agent.agent_email == ''
      data_is_na = true  
    else
      agent_is_pm = false
      pm_users = @property.property_manager_users
      pm_users.each do |pm_user|
        if pm_user.name == sales_for_agent.agent
          data_is_na = true
          break
        end
      end
    end 

    if data_is_na 
      return {data_is_na: true, num_of_goals_reached: num_of_goals_reached, num_of_active_months: num_of_active_months}
    end

    months = first_and_last_days_of_past_twelve_months()
    months.each do |m|
      agent_starting_month = SalesForAgent.where(property: @property, agent: sales_for_agent.agent, date: m[0]).first
      agent_ending_month = SalesForAgent.where(property: @property, agent: sales_for_agent.agent, date: m[1]).first
      if agent_starting_month.nil? || agent_ending_month.nil?
        break
      end

      num_of_active_months += 1
      # Determine of goal reached for month
      agent_goal = agent_ending_month.goal
      agent_sales = agent_ending_month.sales

      if agent_ending_month.goal_for_slack.present?
        agent_goal_for_slack = agent_ending_month.goal_for_slack
      else  
        agent_goal_for_slack = agent_goal
      end

      puts agent_sales
      puts agent_goal

      if agent_sales >= agent_goal
        num_of_goals_reached += 1
      end  
    end
    
    return {data_is_na: false, num_of_goals_reached: num_of_goals_reached, num_of_active_months: num_of_active_months}
  end

  # For Leasing Agents Table
  def first_and_last_days_of_past_twelve_months(value=Date.today)
    latest_end_month = (Date.today + 1.day - 1.month).end_of_month
    num_of_months = 12
    dates = (1..num_of_months).to_a.
      map{ |m| (Date.today + 1.day - m.months).end_of_month }.
      map{ |d| [d.beginning_of_month, d] }
    return dates
  end

end
