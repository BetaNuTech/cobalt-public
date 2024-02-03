require 'logger'

module Leasing
  module Commands
    class FindMonthlyStars
      def initialize(end_of_month_date: )
        @end_of_month_date = end_of_month_date
      end

      # Return values:
      # 
      def perform
        puts "Func Leasing::Commands::FindMonthlyStars called"
        blacklist_props = Property.all_blacklist_codes()
      
        leasing_stars = []
        leasing_super_stars = []
        leasing_goals_missed = []
      
        Property.where.not(code: blacklist_props).order("full_name ASC").each do |property| 
          data = find_leasing_stars(property)

          if data.nil?
            next
          end

          star_agents = data[:star_agents]
          unless star_agents.count == 0
            star_agents.each do |agent|
              percentage = 100

              if agent.goal_for_slack.present?
                agent_goal_for_slack = agent.goal_for_slack
              else  
                agent_goal_for_slack = agent.goal
              end

              if agent_goal_for_slack > 0
                percentage = (agent.sales.to_f / agent_goal_for_slack.to_f * 100.0)
              end
    
              # Find Number of Past Stars
              past_star_records = SalesForAgent.where(agent: agent.agent).where(star_received: true).where("date < ?", @end_of_month_date)
              if !past_star_records.nil? && past_star_records.count > 0
                past_star_count = past_star_records.count
              else
                past_star_count = 0
              end
    
              leasing_stars.push( { "agent" => agent.agent, 
                                    "property" => property.code, 
                                    "sales" => agent.sales, 
                                    "goal" => agent_goal_for_slack, 
                                    "percentage" => percentage.round,
                                    "past_stars" => past_star_count,
                                    "super_star" => agent.super_star_received } ) 
                                    
              if agent.super_star_received == true 
                # Find Number of Past Super Stars
                past_super_star_records = SalesForAgent.where(agent: agent.agent).where(super_star_received: true).where("date < ?", @end_of_month_date)
                if !past_super_star_records.nil? && past_super_star_records.count > 0
                  past_super_star_count = past_super_star_records.count
                else
                  past_super_star_count = 0
                end
                leasing_super_stars.push( { "agent" => agent.agent, 
                                            "property" => property.code, 
                                            "sales" => agent.sales, 
                                            "goal" => agent_goal_for_slack, 
                                            "percentage" => percentage.round,
                                            "past_super_stars" => past_super_star_count} ) 
              end
            end
          end

          agents_missing_goal = data[:agents_missing_goal]
          unless agents_missing_goal.count == 0
            agents_missing_goal.each do |agent|
              # Find Number of Missed Goals, in the past 12 months
              past_missed_goal_records = SalesForAgent.where(agent: agent.agent).where(missed_goal: true).where("date < ?", @end_of_month_date).where("date >= ?", @end_of_month_date - 12.months - 3.days)
              if !past_missed_goal_records.nil? && past_missed_goal_records.count > 0
                past_missed_goal_count = past_missed_goal_records.count
              else
                past_missed_goal_count = 0
              end
              leasing_goals_missed.push( {  "agent" => agent.agent, 
                                            "property" => property.code, 
                                            "sales" => agent.sales, 
                                            "goal" => agent.goal,
                                            "past_missed_goals" => past_missed_goal_count} ) 
            end
          end

        end
      
        if leasing_stars.count > 0
          # puts "Sorting ALL leasing_stars"
          leasing_stars.sort! do |a, b|
            if b['sales'] > a['sales']
              1
            elsif a['sales'] > b['sales']
              -1
            elsif b['percentage'] > a['percentage']
              1
            elsif a['percentage'] > b['percentage']
              -1
            else
              a['property'] <=> b['property']
            end
          end
        end

        if leasing_super_stars.count > 0
          # puts "Sorting ALL leasing_super_stars"
          leasing_super_stars.sort! do |a, b|
            if b['property'] < a['property']
              1
            elsif a['property'] < b['property']
              -1
            elsif b['sales'] > a['sales']
              1
            elsif a['sales'] > b['sales']
              -1
            else
              a['agent'] <=> b['agent']
            end
          end
        end

        if leasing_goals_missed.count > 0
          # puts "Sorting ALL leasing_goals_missed"
          leasing_goals_missed.sort! do |a, b|
            if b['property'] < a['property']
              1
            elsif a['property'] < b['property']
              -1
            else
              a['agent'] <=> b['agent']
            end
          end
        end

        # Group by team
        leasing_stars_by_teams = group_by_team(data: leasing_stars)
        leasing_super_stars_by_teams = group_by_team(data: leasing_super_stars)

        # Group by property
        leasing_stars_by_properties = group_by_property(data: leasing_stars)
        leasing_super_stars_by_properties = group_by_property(data: leasing_super_stars)
        leasing_goals_missed_by_properties = group_by_property(data: leasing_goals_missed)

        return {  
          leasing_stars: leasing_stars, 
          leasing_super_stars: leasing_super_stars, 
          leasing_goals_missed: leasing_goals_missed,
          leasing_super_stars_by_teams: leasing_super_stars_by_teams, 
          leasing_stars_by_properties: leasing_stars_by_properties,
          leasing_super_stars_by_properties: leasing_super_stars_by_properties, 
          leasing_goals_missed_by_properties: leasing_goals_missed_by_properties 
        }
      end

      def group_by_team(data: )
        leasing_data_for_team = []
        teams_with_leasing_data = []
        teams = Property.teams.where(active: true).each do |team|
          team_property_codes = Property.properties.where(active: true, team_id: team.id).pluck('code')
          data.each do |agent_data|
            if team_property_codes.include?(agent_data["property"])
              leasing_data_for_team.push(agent_data)
            end
          end
          teams_with_leasing_data.push( {team: team, leasing_data: leasing_data_for_team})
          leasing_data_for_team = []
        end

        return teams_with_leasing_data
      end

      def group_by_property(data: )
        leasing_data_for_property = []
        properties_with_leasing_data = []
        properties = Property.properties.where(active: true).each do |property|
          data.each do |agent_data|
            if agent_data["property"] == property.code
              leasing_data_for_property.push(agent_data)
            end
          end
          properties_with_leasing_data.push( {property: property, leasing_data: leasing_data_for_property})
          leasing_data_for_property = []
        end

        return properties_with_leasing_data
      end


      def find_leasing_stars(property)
        puts "Func Leasing::Commands::FindMonthlyStars - find_leasing_stars called for #{property.code}"
        metric = Metric.where(property: property, date: @end_of_month_date).first
        metric_next_day = Metric.where(property: property, date: @end_of_month_date + 1.day).first
        # Property needed to have achieved their goal for the month
        if metric.nil?
          return nil
        end
      
        property_goal_reached = false
      
        # Add last day leases
        if !metric_next_day.nil?
          leases = metric.leases_attained_adjusted
          if leases.nil?
            leases = metric_next_day.leases_last_24hrs
          else
            leases += metric_next_day.leases_last_24hrs
          end
          total_goal = metric.total_lease_goal_adjusted
          if !leases.nil? && !total_goal.nil?
            property_goal_reached = Metric.calc_percentage(leases, total_goal) >= 100
          end
        else
          property_goal_reached = metric.percent_of_lease_goal_adjusted >= 100
        end
      
        # Filter out agents that didn't start at the beginning of the month
        agents_ending_month = SalesForAgent.where(property: property).where(date: @end_of_month_date).order("agent ASC")
        agents_starting_month = SalesForAgent.where(property: property).where(date: @end_of_month_date.beginning_of_month).order("agent ASC")
        
        agents = []
        agents_starting_month.each do |agent_starting|
          agents_ending_month.each do |agent_ending|
            if agent_starting.agent == agent_ending.agent 
              agents << agent_ending
              break
            end
          end
        end

        star_agents = []
        agents_missing_goal = []
        agents.each do |agent|
          # Grab the corrected sales # from the 1st of the month, looking back at whole month
          # This is due to the fact that we don't know the last day of month sales.
          agent_for_all_sales = SalesForAgent.where(property: property).where(agent: agent.agent).where(date: @end_of_month_date + 1.day).first
          if !agent_for_all_sales.nil? && !agent_for_all_sales.sales_prior_month.nil?
            agent.sales = agent_for_all_sales.sales_prior_month
          end

          agent_goal = agent.goal
          agent_sales = agent.sales

          if agent.goal_for_slack.present?
            agent_goal_for_slack = agent.goal_for_slack
          else  
            agent_goal_for_slack = agent_goal
          end
      
          star_agent = false
          super_star_agent = false
          missed_goal = false

          # SUPER STAR LOGIC
          # If the property had reached their lease goal of 100% or higher
          #   and they reached 100% or higher in leases, for their (super star) goal -> SUPER STAR
          if property_goal_reached
            if agent.super_star_goal.present? && agent_sales >= agent.super_star_goal
              super_star_agent = true
            end
          end

          # STAR Logic
          # If agent's (slack) goal is > 0
          #   and they reached 100% or higher in leases, for their (slack) goal  -> STAR
          # If the agent's (slack) goal is <= 0
          #   and they got 1 or more leases -> STAR
          if agent_goal_for_slack > 0 && agent_sales >= agent_goal_for_slack
            star_agent = true
          elsif agent_goal_for_slack <= 0 && agent_sales >= 1
            star_agent = true
          end

          # TODO: Waiting to hear back in #coding if we need > 0 goal.
          if agent_sales < agent_goal
            # Make sure this is not a PM.  If so, exclude PM.
            if agent.property.present?
              agent_is_pm = false
              pm_users = agent.property.property_manager_users
              pm_users.each do |pm_user|
                if agent.agent_email.present?
                  if agent.agent_email == pm_user.email 
                    agent_is_pm = true
                    puts "PM FOUND (by email): #{agent.agent}"
                    break
                  end
                elsif pm_user.name == agent.agent
                  agent_is_pm = true
                  puts "PM FOUND (by name): #{agent.agent}"
                  break
                end
              end

              if !agent_is_pm
                missed_goal = true
              end
            end
          end

          agent.star_received = star_agent
          agent.super_star_received = super_star_agent
          agent.missed_goal = missed_goal
      
          unless agent.agent.downcase == 'other' || agent.agent_email.nil? || agent.agent_email == ''
            if star_agent == true
              star_agents.append(agent)
            elsif missed_goal == true
              agents_missing_goal.append(agent)
            end
          end
      
          agent.save!
        end
      
        return { star_agents: star_agents, agents_missing_goal: agents_missing_goal }
      end

    end
  end
end
