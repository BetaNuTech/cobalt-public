require 'roo'
require 'set'

module Metrics
  module Commands
    class ImportExcelSpreadsheet
      include ActionView::Helpers::NumberHelper
      
      def initialize(spreadsheet_file_path, root_url)
        @spreadsheet_file_path = spreadsheet_file_path
        @root_url = root_url
      end
      
      def perform
        @logger = Logger.new(STDOUT)

        if !@spreadsheet_file_path.end_with?("xlsx")
          return
        end

        file_extension = File.extname(@spreadsheet_file_path)
        file_extension[0] = '' # remove the dot
        
        if file_extension.blank?
          file_extension = "xlsx"
        end

        @logger.debug "Opening XLSX File: #{@spreadsheet_file_path}"
        
        spreadsheet = Roo::Spreadsheet.open(@spreadsheet_file_path,
          extension: file_extension)
          
        ActiveRecord::Base.transaction do
          first_row = spreadsheet.row(1)
          title = first_row[0]
          @logger.debug "XLSX Title: #{title}"

          if title.to_s == 'Cobalt Daily Report' || title.to_s == 'Cobalt Daily Report - Region'
            import(spreadsheet) # Metrics
          elsif title.to_s.start_with? 'Rent Change'
            import_rent_change_reasons(spreadsheet) # RentChangeReasons
          elsif title.to_s.start_with? 'Red Bot Compliance'
            import_compliance_issues(spreadsheet) # ComplianceIssues
          elsif title.to_s.start_with? 'AP Redbot Compliance Report'
            import_accounts_payable_compliance_issues(spreadsheet) # AccountsPayableComplianceIssues
          elsif title.to_s == 'People Problem Report'
            # Replaced by Leads Problem Report
            # import_people_problem_report(spreadsheet) # ConversionsForAgents
          elsif title.to_s == 'Cobalt Agent Sales Report'
            import_agent_sales_report(spreadsheet) # SalesForAgents
          elsif title.to_s == 'Leads Problem Report'
            import_leads_problem_report(spreadsheet) # ConversionsForAgents & Properties
          elsif title.to_s == 'Redbot Maintenance Report'
            import_redbot_maintenance_report(spreadsheet) # TurnsForProperties
          elsif title.to_s == 'Bluestone Work Order Incomplete List'
            import_incomplete_work_orders(spreadsheet) # IncompleteWorkOrders
          elsif title.to_s.downcase == 'costar market data'
            import_costar_market_data(spreadsheet: spreadsheet, in_development: false) # CostarMarketDatum
          elsif title.to_s.downcase == 'costar market pref data'
            import_costar_market_data(spreadsheet: spreadsheet, in_development: true) # CostarMarketDatum
          elsif title.to_s == 'Cobalt Portfolio Sales Addendum'
            import_portfolio_leads_data(spreadsheet) # Metric
          elsif title.to_s == 'Cobalt Unknown Detail Report'
            import_renewals_unknown_details(spreadsheet) # RenewalsUnknownDetails
          elsif title.to_s == 'Cobalt Collection Detail Report'
            import_collections_non_eviction_past20_details(spreadsheet) # CollectionNonEvictionPast20Details
          elsif title.to_s == 'Cobalt Rent Detail Report'
            import_average_rents_bedroom_details(spreadsheet) # AverageRentsBedroomDetails
          elsif title.to_s.downcase == 'comp survey by bed summary'
            import_comp_survey_by_bed_details(spreadsheet) # AverageRentsBedroomDetails
          elsif title.to_s.downcase == 'collections snapshot'
            import_collections_details(spreadsheet) # CollectionsDetails
          elsif title.to_s.downcase == 'collections snapshot by tenant'
            import_collections_by_tenant_details(spreadsheet) # CollectionsByTenantDetails
          elsif title.to_s.downcase == 'diversity & inclusion calendar'
            import_calendar_bot_events(spreadsheet) # CalendarBotEvent
          end
        
        end
      end
      
      private
      def import(spreadsheet)
        # Data Date
        date = nil 

        for i in (7..spreadsheet.last_row)
          row = spreadsheet.row(i)
          if row[0].nil?
            next
          end
          
          date = get_date(row, 0)
          if date.nil?
            next
          end

          property = get_or_create_property(row)
          update_property_full_name(property, row)
          
          metric = get_new_or_existing_metric(property, date)

          metric.position = metric.property.get_position
          
          assign_values_to_metric(row, metric)

          metric.main_metrics_received = true
          
          metric.save!

          # Update last day of the month leases, if date is the 1st.
          if date.day == 1
            last_of_month_metric = Metric.find_by(property: property, date: date - 1.day)
            if last_of_month_metric&.leases_last_24hrs_applied == false
              last_of_month_metric.update_columns(
                leases_attained: last_of_month_metric.leases_attained + metric.leases_last_24hrs,
                leases_last_24hrs_applied: true
              )
            end
          end

          # Continue, only if recent data
          if date >= (Date.today - 1.day) && property.code != Property.portfolio_code() && property.type != "Team"
            Property.update_property_blue_shift_status(property, date, true)
            Property.update_property_maint_blue_shift_status(property, date, true)
            Property.update_property_trm_blue_shift_status(property, date, true)
  
            send_leasing_goal_slack_message(property, metric, date)
          end
        end

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::YARDI,
          data_date: date, 
          data_datetime: nil, 
          title: DataImportRecordYardiSpreadSheetTitle::CobaltDailyReport)
        new_record.data_imported = date.present?
        new_record.save!
        new_record.sendNoficationToSlack()
      end

      def import_portfolio_leads_data(spreadsheet)
        # Data Date
        date = nil 

        for i in (7..spreadsheet.last_row)
          row = spreadsheet.row(i)
          if row[0].nil?
            next
          end
          
          date = get_date(row, 0)
          if date.nil?
            next
          end

          property = get_or_create_property(row)          
          metric = get_new_or_existing_metric(property, date)
          metric.position = metric.property.get_position
          
          metric.leases_attained = get_decimal_from_string(row[2])
          metric.leases_goal = get_decimal_from_string(row[3])
          metric.addendum_received = true
          
          metric.save!

          # Update last day of the month leases, if date is the 1st.
          if date.day == 1
            last_of_month_metric = Metric.where(property: property, date: date - 1.day).first
            if !last_of_month_metric.nil?
              if !last_of_month_metric.leases_last_24hrs_applied
                last_of_month_metric.leases_attained += metric.leases_last_24hrs
                last_of_month_metric.leases_last_24hrs_applied = true
                last_of_month_metric.save!
              end
            end
          end

          # Continue, only if recent data
          if date >= (Date.today - 1.day)
            send_leasing_goal_slack_message(property, metric, date)
          end
        end

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::YARDI, 
          data_date: date,
          data_datetime: nil,  
          title: DataImportRecordYardiSpreadSheetTitle::CobaltPortfolioSalesAddendum)
        new_record.data_imported = date.present?
        new_record.save!
        new_record.sendNoficationToSlack()
      end

      def import_rent_change_reasons(spreadsheet)
        # Data Date
        date = nil 
        data_saved = false
        for i in (7..spreadsheet.last_row)
          row = spreadsheet.row(i)
          if row[0].nil?
            next
          end

          date = get_date(row, 0)
          if date.nil?
            next
          end

          property = get_property(row)
          unit_type_code = row[2].to_s.strip

          unless property.nil? || unit_type_code.nil? || (!unit_type_code.nil? && unit_type_code == "")
            rent_change_reason = get_new_or_existing_rent_change_reason(property, date, unit_type_code)
            assign_values_to_rent_change_reason(row, rent_change_reason)
            rent_change_reason.save!
            data_saved = true
          end     
        end

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::YARDI, 
          data_date: date,
          data_datetime: nil, 
          title: DataImportRecordYardiSpreadSheetTitle::RentChangeSuggestionReport)
        new_record.data_imported = data_saved
        new_record.save!
        new_record.sendNoficationToSlack()
      end

      def import_compliance_issues(spreadsheet)
        property_ids_with_issues = Set.new

        issues_date = nil
        data_saved = false
        for i in (7..spreadsheet.last_row)
          row = spreadsheet.row(i)
          if row[0].nil?
            next
          end

          date = get_date(row, 0)
          if date.nil?
            next
          end

          issues_date = date
          property = get_property(row)
          issue = row[2].to_s.strip

          if !property.nil? && !issue.nil?
            compliance_issue = get_new_or_existing_compliance_issue(date, property, issue)
            assign_values_to_compliance_issue(row, compliance_issue)
            compliance_issue.save!
            data_saved = true

            puts "import_compliance_issues: Adding #{property.code} for new issue."
            property_ids_with_issues.add(compliance_issue.property_id)
          end
        end

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::YARDI, 
          data_date: issues_date, 
          data_datetime: nil, 
          title: DataImportRecordYardiSpreadSheetTitle::RedBotComplianceReport)
        new_record.data_imported = data_saved
        new_record.save!
        new_record.sendNoficationToSlack()

        # if no data, return
        if issues_date.nil?
          return  
        end

        blacklist_props = Property.all_blacklist_codes()
        all_properties = Property.where.not(code: blacklist_props).order("code ASC")

        # Find all other properties, with TRM only issues
        property_ids_with_trm_issues = Set.new
        all_properties.each do |p|
          issues = ComplianceIssue.where(date: issues_date, property: p, trm_notify_only: true)
          if issues.count > 0
            puts "import_trm_compliance_issues: Adding #{p.code} for existing issue(s) only."
            property_ids_with_trm_issues.add(p.id)
          end
        end

        # Send to private HR Team channel, in Corporate Workspace
        property_ids_with_trm_issues.each do |i|
          # Determine team code, from property or property as team?
          property = Property.find(i)
          if property.nil?
            @logger.debug "ERROR: TRM Compliance Corp Alert Job Creation failed, no property found Property ID: #{i}"            
            next # skip this property
          end

          channel = "#trm-compliance-alerts"
          mention = property.corp_talent_resource_manager_mention(nil)
          issues_ordered = ComplianceIssue.where(date: issues_date, property: property, trm_notify_only: true).order('issue ASC')
          message = message_for_trm_compliance_issues(property, mention, issues_ordered)
          send_corp_red_bot_slack_alert(message, channel)
          @logger.debug "TRM Compliance Corp Alert Job Created for channel: #{channel}, with mention: #{mention}, message: #{message}"            
        end

        # Send Alerts, if recent issues and issues are for Tuesday only (unless in test mode)
        day_of_the_week = issues_date.strftime("%A")
        if issues_date < (Date.today - 1.day) || (day_of_the_week != 'Tuesday' && Settings.slack_test_mode != 'enabled')
          return
        end

        # Find all other properties, with issues
        all_properties.each do |p|
          if !property_ids_with_issues.include?(p.id)
            issues = ComplianceIssue.where(date: issues_date, property: p, trm_notify_only: false)
            if issues.count > 0
              puts "import_compliance_issues: Adding #{p.code} for existing issue(s) only."
              property_ids_with_issues.add(p.id)
            end
          end
        end

        property_ids_with_issues.each do |i|
          property = Property.find(i)
          unless property.slack_channel.nil?
            property_manager_usernames = property.property_manager_mentions(nil)
            issues_ordered = ComplianceIssue.where(date: issues_date, property: property, trm_notify_only: false).order('issue ASC')
            message = message_for_compliance_issues(property, property_manager_usernames, issues_date, issues_ordered)
            @logger.debug "Compliance Alert Job Created, with message: #{message}"
            channel = property.update_slack_channel
            send_red_bot_slack_alert_image(channel, '!!Compliance Alert!!', 'redbot_alert_image_v2.png')
            send_red_bot_slack_alert(message, channel)
            if !Settings.redbot_strikes_disabled && !property_manager_usernames.empty?
              issues_ordered_last_week = ComplianceIssue.where(date: (issues_date - 7.days), property: property, trm_notify_only: false).order('issue ASC')
              issues_ordered_14_days_ago = ComplianceIssue.where(date: (issues_date - 14.days), property: property, trm_notify_only: false).order('issue ASC')
              issues_ordered_21_days_ago = ComplianceIssue.where(date: (issues_date - 21.days), property: property, trm_notify_only: false).order('issue ASC')
              issues_ordered_28_days_ago = ComplianceIssue.where(date: (issues_date - 28.days), property: property, trm_notify_only: false).order('issue ASC')
              @logger.debug "Check for Compliance Inactions"
              check_for_compliance_inaction(property, property_manager_usernames, issues_ordered, issues_ordered_last_week, issues_ordered_14_days_ago, issues_ordered_14_days_ago, issues_ordered_28_days_ago)
            end
          end
        end

      end


      def import_accounts_payable_compliance_issues(spreadsheet)
        issues_date = nil
        data_saved = false
        for i in (7..spreadsheet.last_row)
          row = spreadsheet.row(i)
          if row[0].nil?
            next
          end

          date = get_date(row, 0)
          if date.nil?
            next
          end

          issues_date = date
          property = get_property(row)
          issue = row[2].to_s.strip

          if !property.nil? && !issue.nil?
            compliance_issue = get_new_or_existing_accounts_payable_compliance_issue(date, property, issue)
            assign_values_to_accounts_payable_compliance_issue(row, compliance_issue)
            compliance_issue.save!
            data_saved = true
          end
        end

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::YARDI, 
          data_date: issues_date, 
          data_datetime: nil, 
          title: DataImportRecordYardiSpreadSheetTitle::APRedBotComplianceReport)
        new_record.data_imported = data_saved
        new_record.save!
        new_record.sendNoficationToSlack()

        # if no data, return
        if issues_date.nil?
          return  
        end

        # Send Alerts, if recent issues and issues are for Monday only (unless in test mode)
        day_of_the_week = issues_date.strftime("%A")
        if issues_date < (Date.today - 1.day)
          return
        end

        issues_ordered = AccountsPayableComplianceIssue.joins(:property).where(date: issues_date).order('issue ASC, properties.code ASC')
        if issues_ordered.count == 0
          @logger.debug "No AP Compliance Issues"
          return
        end

        message = "@ft-team: `AP Compliance Issues`\n\n"
        current_issue = ""
        issues_ordered.each do |c|
          if current_issue != c.issue
            current_issue = c.issue
            message += "*#{current_issue}*\n"
          end
          culprits_formatted = c.culprits.gsub(';','` `')
          message += "- #{c.property.code} - #{number(c.num_of_culprits)} - `#{culprits_formatted}`\n"
        end

        @logger.debug "AP Compliance Alert Job Created, with message: #{message}"
        channel = "#ft"
        send_corp_red_bot_slack_alert(message, channel)
      end

      # def import_people_problem_report(spreadsheet)
      #   for i in (7..spreadsheet.last_row)
      #     row = spreadsheet.row(i)
      #     if row[0].nil?
      #       next
      #     end
      #     date = get_date(row)
      #     property = get_property(row)
      #     agent = row[2].strip

      #     if !property.nil? && !agent.nil?
      #       conversions_for_agent = get_new_or_existing_conversions_for_agent(date, property, agent)
      #       assign_values_to_conversions_for_agent(row, conversions_for_agent)
      #       conversions_for_agent.save!
      #     end
      #   end    
      # end

      def import_leads_problem_report(spreadsheet)
        # Data Date
        date = nil 
        data_saved = false
        for i in (7..spreadsheet.last_row)
          row = spreadsheet.row(i)
          if row[0].nil?
            next
          end
          date = get_date(row, 0)
          if date.nil?
            next
          end

          property = get_property(row)
          agent = row[2].to_s.strip

          if !property.nil? && !agent.nil?
            conversions_for_agent = get_new_or_existing_conversions_for_agent(date, property, agent)
            assign_leads_values_to_conversions_for_agent(row, conversions_for_agent)
            conversions_for_agent.save!
            data_saved = true
          end
        end 
        
        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::YARDI, 
          data_date: date, 
          data_datetime: nil, 
          title: DataImportRecordYardiSpreadSheetTitle::LeadsProblemReport)
        new_record.data_imported = data_saved
        new_record.save!
        new_record.sendNoficationToSlack()
      end

      def import_agent_sales_report(spreadsheet)
        import_date = nil
        data_saved = false
        for i in (7..spreadsheet.last_row)
          row = spreadsheet.row(i)
          if row[0].nil?
            next
          end
          date = get_date(row, 0)
          if date.nil?
            next
          end

          property = get_property(row)
          agent = row[2].to_s.strip
          
          if !property.nil? && !agent.nil?
            sales_for_agent = get_new_or_existing_sales_for_agent(date, property, agent)
            assign_values_to_sales_for_agent(row, sales_for_agent)
            sales_for_agent.save!
            data_saved = true
            import_date = date                      
          end
        end   

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::YARDI, 
          data_date: import_date, 
          data_datetime: nil, 
          title: DataImportRecordYardiSpreadSheetTitle::CobaltAgentSalesReport)
        new_record.data_imported = data_saved
        new_record.save!
        new_record.sendNoficationToSlack()

        # Only send latest data to channels
        if import_date.nil? || import_date < Date.today - 1.day
          return
        end
        
        # Send images to slack
        sales_for_agents = SalesForAgent.where(date: import_date).order("property_id ASC, agent ASC")
        if !sales_for_agents.nil? && sales_for_agents.count > 0
          current_property = sales_for_agents[0].property
          leasing_goals = []
          for sfa in sales_for_agents do
            property = sfa.property

            if current_property.id != property.id
              send_slack_image_leasing_goals(current_property, import_date, leasing_goals)              

              leasing_goals = [] # Reset
            end

            agent = sfa.agent
            sales = sfa.sales
            goal = sfa.goal
            progress = ''
            if goal <= 0
              if sales > goal
                progress = '100'
              else
                progress = '0'
              end
            else
              progress = "#{number(sales.to_f/goal.to_f * 100.0)}"
            end
            ratio = "#{number(sales)}/#{number(goal)}"
            leasing_goals.push( { "agent" => agent, "progress" => progress, "ratio" => ratio } )  
            
            current_property = property                        
          end

          if leasing_goals.count > 0
            send_slack_image_leasing_goals(current_property, import_date, leasing_goals)            
          end

        end
      end
        
      def import_redbot_maintenance_report(spreadsheet)
        import_date = nil
        data_saved = true
        for i in (7..spreadsheet.last_row)
          row = spreadsheet.row(i)
          if row[0].nil?
            next
          end
          date = get_date(row, 0)
          if date.nil?
            next
          end

          property = get_property(row)
          
          if !property.nil?
            turns_for_property = get_new_or_existing_turns_for_property(date, property)
            assign_values_to_turns_for_property(row, turns_for_property)
            turns_for_property.save!
            data_saved = true
            import_date = date                      
          end
        end 

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::YARDI, 
          data_date: import_date, 
          data_datetime: nil, 
          title: DataImportRecordYardiSpreadSheetTitle::RedbotMaintenanceReport)
        new_record.data_imported = data_saved
        new_record.save!
        new_record.sendNoficationToSlack()

        # Only send latest data to channels
        if import_date.nil? || import_date < Date.today - 1.day
          return
        end

        # Send images to slack
        turns_for_properties = TurnsForProperty.where(date: import_date).order("property_id ASC")
        if !turns_for_properties.nil? && turns_for_properties.count > 0
          # Daily
          for tfp in turns_for_properties do
            send_slack_image_maint_work_orders(tfp)            
          end

          day_of_the_week = import_date.strftime("%A")

          # Only on Tuesdays
          if day_of_the_week == 'Tuesday'
            for tfp in turns_for_properties do
              send_slack_image_maint_turns_goal(tfp)            
            end
          end
        end
      end

      def import_incomplete_work_orders(spreadsheet)
        call_date = nil
        data_saved = false
        for i in (7..spreadsheet.last_row)
          row = spreadsheet.row(i)
          if row[0].nil? || row[4].nil?
            next
          end
          call_date = get_date(row, 4)
          property = get_property(row)
          work_order = row[3].to_s
          
          if !call_date.nil? && !property.nil? && !work_order.nil?
            incomplete_work_order = get_new_or_existing_incomplete_work_order(call_date, property, work_order)
            assign_values_to_incomplete_work_order(row, incomplete_work_order) # if updated, saved too
            incomplete_work_order.save!
            data_saved = true
          end
        end

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::YARDI, 
          data_date: call_date, 
          data_datetime: nil, 
          title: DataImportRecordYardiSpreadSheetTitle::BluestoneWorkOrderIncompleteList)
        new_record.data_imported = data_saved
        new_record.save!
        new_record.sendNoficationToSlack()
      end

      def import_costar_market_data(spreadsheet:, in_development:)
        date = nil
        data_saved = false
        for i in (3..spreadsheet.sheet(0).last_row)
          row = spreadsheet.row(i)
          if row[0].nil? || row[1].nil?
            next
          end
          date = get_date(row, 0)
          property = get_property(row)

          # Set new property inactive, if in development still
          if property.nil? && in_development == true
            property = get_or_create_property(row)
            property.active = false
            property.save!
          end
          
          if !date.nil? && !property.nil?
            costar_market_datum = get_new_or_existing_costar_market_datum(date, property)
            assign_values_to_costar_market_datum(row, costar_market_datum) # if updated, saved too
            costar_market_datum.in_development = in_development
            costar_market_datum.save!
            data_saved = true
          end
        end

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::COSTAR, 
          data_date: date, 
          data_datetime: nil, 
          title: DataImportRecordCostarSpreadSheetTitle::CostarMarketData)
        new_record.data_imported = data_saved
        new_record.save!
        new_record.sendNoficationToSlack()
      end

      def import_renewals_unknown_details(spreadsheet)
        date = nil
        data_saved = false
        for i in (7..spreadsheet.last_row)
          row = spreadsheet.row(i)
          if row[0].nil? || row[1].nil? || row[2].nil?
            next
          end
          date = get_date(row, 0)
          property = get_property(row)
          yardi_code = row[2].to_s
          
          if !date.nil? && !property.nil? && !yardi_code.nil?
            renewals_unknown_detail = get_new_or_existing_renewals_unknown_detail(date, property, yardi_code)
            assign_values_to_renewals_unknown_detail(row, renewals_unknown_detail) # if updated, saved too
            renewals_unknown_detail.save!
            data_saved = true
          end
        end

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::YARDI, 
          data_date: date, 
          data_datetime: nil, 
          title: DataImportRecordYardiSpreadSheetTitle::CobaltUnknownDetailReport)
        new_record.data_imported = data_saved
        new_record.save!
        new_record.sendNoficationToSlack()
      end

      def import_collections_non_eviction_past20_details(spreadsheet)
        date = nil
        data_saved = false
        for i in (7..spreadsheet.last_row)
          row = spreadsheet.row(i)
          if row[0].nil? || row[1].nil? || row[2].nil?
            next
          end
          date = get_date(row, 0)
          property = get_property(row)
          yardi_code = row[2].to_s
          
          if !date.nil? && !property.nil? && !yardi_code.nil?
            collections_detail = get_new_or_existing_collections_non_eviction_past20_detail(date, property, yardi_code)
            assign_values_to_collections_non_eviction_past20_detail(row, collections_detail) # if updated, saved too
            collections_detail.save!
            data_saved = true
          end
        end

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::YARDI, 
          data_date: date, 
          data_datetime: nil, 
          title: DataImportRecordYardiSpreadSheetTitle::CobaltCollectionDetailReport)
        new_record.data_imported = data_saved
        new_record.save!
        new_record.sendNoficationToSlack()
      end

      def import_average_rents_bedroom_details(spreadsheet)
        date = nil
        data_saved = false
        for i in (7..spreadsheet.last_row)
          row = spreadsheet.row(i)
          if row[0].nil? || row[1].nil? || row[2].nil?
            next
          end
          date = get_date(row, 0)
          property = get_property(row)
          num_of_bedrooms = get_decimal_from_string(row[2])
          
          if !date.nil? && !property.nil? && num_of_bedrooms != 0
            average_rents_bedroom_detail = get_new_or_existing_average_rents_bedroom_detail(date, property, num_of_bedrooms)
            assign_values_to_average_rents_bedroom_detail(row, average_rents_bedroom_detail) # if updated, saved too
            average_rents_bedroom_detail.save!
            data_saved = true

            # Set/Update Metric with average rent by bed details
            if average_rents_bedroom_detail.nom_of_new_leases > 0 || average_rents_bedroom_detail.num_of_renewal_leases > 0
              metric = get_new_or_existing_metric(property, date)
              metric.position = metric.property.get_position

              average_rent_net_effective = nil
              average_rent_new_leases = nil
              average_rent_renewal_leases = nil

              calc_sum = 0.0
              if average_rents_bedroom_detail.new_lease_average_rent.present?
                calc_sum = average_rents_bedroom_detail.new_lease_average_rent * average_rents_bedroom_detail.nom_of_new_leases
              end
              if average_rents_bedroom_detail.renewal_lease_average_rent.present?
                calc_sum += average_rents_bedroom_detail.renewal_lease_average_rent * average_rents_bedroom_detail.num_of_renewal_leases
              end

              average_rent_net_effective = calc_sum / (average_rents_bedroom_detail.nom_of_new_leases + average_rents_bedroom_detail.num_of_renewal_leases)

              if average_rents_bedroom_detail.nom_of_new_leases > 0
                average_rent_new_leases = average_rents_bedroom_detail.new_lease_average_rent
              end

              if average_rents_bedroom_detail.num_of_renewal_leases > 0
                average_rent_renewal_leases = average_rents_bedroom_detail.renewal_lease_average_rent
              end

              case average_rents_bedroom_detail.num_of_bedrooms
              when 1
                metric.average_rent_1bed_net_effective = average_rent_net_effective
                metric.average_rent_1bed_new_leases = average_rent_new_leases
                metric.average_rent_1bed_renewal_leases = average_rent_renewal_leases
                metric.save!
              when 2
                metric.average_rent_2bed_net_effective = average_rent_net_effective
                metric.average_rent_2bed_new_leases = average_rent_new_leases
                metric.average_rent_2bed_renewal_leases = average_rent_renewal_leases
                metric.save!
              when 3
                metric.average_rent_3bed_net_effective = average_rent_net_effective
                metric.average_rent_3bed_new_leases = average_rent_new_leases
                metric.average_rent_3bed_renewal_leases = average_rent_renewal_leases
                metric.save!
              when 4
                metric.average_rent_4bed_net_effective = average_rent_net_effective
                metric.average_rent_4bed_new_leases = average_rent_new_leases
                metric.average_rent_4bed_renewal_leases = average_rent_renewal_leases
                metric.save!
              else
                puts "ERROR: average_rents_bedroom_detail.num_of_bedrooms = " + average_rents_bedroom_detail.num_of_bedrooms
              end
            end
          end
        end

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::YARDI, 
          data_date: date, 
          data_datetime: nil, 
          title: DataImportRecordYardiSpreadSheetTitle::CobaltRentDetailReport)
        new_record.data_imported = data_saved
        new_record.save!
        new_record.sendNoficationToSlack()
      end

      def import_comp_survey_by_bed_details(spreadsheet)
        date = nil
        data_saved = false
        for i in (7..spreadsheet.last_row)
          row = spreadsheet.row(i)
          if row[0].nil? || row[1].nil? || row[2].nil?
            next
          end
          date = get_date(row, 0)
          property = get_property(row)
          num_of_bedrooms = get_decimal_from_string(row[2])
          
          if !date.nil? && !property.nil? && num_of_bedrooms != 0
            comp_survey_by_bed_detail = get_new_or_existing_comp_survey_by_bed_detail(date, property, num_of_bedrooms)
            assign_values_to_comp_survey_by_bed_detail(row, comp_survey_by_bed_detail) # if updated, saved too
            comp_survey_by_bed_detail.save!
            data_saved = true
          end
        end

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::YARDI, 
          data_date: date, 
          data_datetime: nil, 
          title: DataImportRecordYardiSpreadSheetTitle::CompSurveyByBedSummary)
        new_record.data_imported = data_saved
        new_record.save!
        new_record.sendNoficationToSlack()
      end

      def import_collections_details(spreadsheet)

        date_time = nil
        data_saved = false
        for i in (6..spreadsheet.last_row)
          row = spreadsheet.row(i)

          # Check for property code
          if row[0].nil?
            next
          end
          property_code = row[0].to_s.strip
          property = Property.where(code: property_code).first
          
          # Check for update to date_time, if any
          if row[1].present? && row[1] != ''
            date_time = DateTime.strptime(row[1],'%s')
          end

          if !date_time.nil? && !property.nil?
            collections_detail = get_new_or_existing_collections_detail(date_time, property)
            assign_values_to_collections_detail(row, collections_detail) # if updated, saved too
            collections_detail.save!
            data_saved = true
          end
        end

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::YARDI, 
          data_date: nil, 
          data_datetime: nil, 
          data_datetime: date_time, 
          title: DataImportRecordYardiSpreadSheetTitle::CollectionsSnapshot)
        new_record.data_imported = data_saved
        new_record.save!
        new_record.sendNoficationToSlack()
      end

      def import_collections_by_tenant_details(spreadsheet)

        date_time = nil
        property = nil
        data_saved = false
        for i in (6..spreadsheet.last_row)
          row = spreadsheet.row(i)

          # Check for tenant code
          if row[0].nil?
            next
          end
          tenant_code = row[0].to_s.strip

          # Check for update to date_time, if any
          if row[1].present? && row[1] != ''
            date_time = DateTime.strptime(row[1].to_s.strip,'%s')
          end

          # Check for update to property, if any
          if row[2].present? && row[2] != ''
            property_code = row[2].to_s.strip
            property = Property.where(code: property_code).first    
          end
          
          if !date_time.nil? && !property.nil? && !tenant_code.nil?
            collections_by_tenant_detail = get_new_or_existing_collections_by_tenant_detail(date_time, property, tenant_code)
            assign_values_to_collections_by_detail_detail(row, collections_by_tenant_detail) # if updated, saved too
            collections_by_tenant_detail.save!
            data_saved = true
          end
        end

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::YARDI, 
          data_date: nil, 
          data_datetime: nil, 
          data_datetime: date_time, 
          title: DataImportRecordYardiSpreadSheetTitle::CollectionsSnapshotByTenant)
        new_record.data_imported = data_saved
        new_record.save!
        new_record.sendNoficationToSlack()
      end

      def import_calendar_bot_events(spreadsheet)
        # Remove all existing events first
        CalendarBotEvent.delete_all
        data_saved = false
        for i in (5..spreadsheet.last_row)
          row = spreadsheet.row(i)

          # Check for date, title, and description
          if row[0].nil? || row[1].nil? || row[2].nil?
            next
          end

          # Assumption: Format is MM/DD/YYYY
          event_date = get_date(row, 0)
          if event_date.nil?
            next
          end

          event = CalendarBotEvent.new()
          event.event_date = event_date
          event.title = row[1].to_s.strip
          event.description = row[2].to_s.strip

          # Assumption: All colors are in #XXXXXX or XXXXXX hex format
          event.border_color = row[3].to_s.strip
          event.background_color = row[4].to_s.strip
          event.text_color = row[5].to_s.strip

          event.save!
          data_saved = true
        end

        # Data Import Record
        new_record = DataImportRecord.emailSpreadsheet(
          source: DataImportRecordSource::MANUAL, 
          data_date: nil, 
          data_datetime: nil, 
          title: DataImportRecordManualSpreadSheetTitle::DiversityInclusionCalendar)
        new_record.data_imported = data_saved
        new_record.save!
        new_record.sendNoficationToSlack()
      end


      def send_slack_image_leasing_goals(current_property, date, leasing_goals)
        if current_property.nil? || current_property.slack_channel.nil? || date.nil? || leasing_goals.nil? || leasing_goals.count == 0
          return
        end

        channel = current_property.slack_channel_for_leasing
        send_image = Alerts::Commands::SendSlackImageLeasingGoals.new(current_property.code, current_property.full_name, date, channel, leasing_goals)
        Job.create(send_image)

        # #prop-<propname> -> @<propname>_leasing

        mention = current_property.bluebot_leasing_mention
        mention += ': ^'
        
        send_alert = Alerts::Commands::SendSlackMessage.new(mention, channel)
        Job.create(send_alert)
      end

      def send_slack_image_maint_turns_goal(turns_for_property)
        if turns_for_property.nil?
          return
        end

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
        
        channel = turns_for_property.property.slack_channel_for_maint
        if !channel.nil? && channel != ''
          send_image = Alerts::Commands::SendMaintBlueBotTurnsGoalSlackImage.new(property_code, property_full_name, date, channel, turns, turns_goal, percent_of_goal, to_do_turns, days_since_goal_reached)
          Job.create(send_image)
  
          mention = turns_for_property.property.bluebot_maint_mention(false, false)
          mention += ' ^'
          
          send_alert = Alerts::Commands::SendMaintBlueBotSlackMessage.new(mention, channel)
          Job.create(send_alert)
        end

        # Send to prop channels as well
        channel = turns_for_property.property.update_slack_channel
        if !channel.nil? && channel != ''
          send_image = Alerts::Commands::SendMaintBlueBotTurnsGoalSlackImage.new(property_code, property_full_name, date, channel, turns, turns_goal, percent_of_goal, to_do_turns, days_since_goal_reached)
          Job.create(send_image)
  
          mention = turns_for_property.property.bluebot_blshift_mention(false)
          mention += ' ^'
          
          send_alert = Alerts::Commands::SendMaintBlueBotSlackMessage.new(mention, channel)
          Job.create(send_alert)
        end
      end

      def send_slack_image_maint_work_orders(turns_for_property)
        if turns_for_property.nil?
          return
        end

        property_code = turns_for_property.property.code
        property_full_name = turns_for_property.property.full_name
        date = turns_for_property.date
        completed_wos = turns_for_property.wo_completed_yesterday
        percent_of_goal = turns_for_property.wo_percent_completed_t30
        incomplete_wos = turns_for_property.wo_open_over_48hrs
        
        channel = turns_for_property.property.slack_channel_for_maint
        if !channel.nil? && channel != ''
          
          # Only send to test channels
          # channel.sub! 'maint', 'test' #TODO: Remove when we go live with this
          #         # channel name changes, due to character limit or otherwise
          # channel.sub! 'bandon', 'bandon-trails' #TODO: remove
          # channel.sub! 'ethan-point', 'ethan-pointe' #TODO: remove

          send_image = Alerts::Commands::SendMaintBlueBotWorkOrdersSlackImage.new(property_code, property_full_name, date, channel, completed_wos, percent_of_goal, incomplete_wos)
          Job.create(send_image)
  
          mention = turns_for_property.property.bluebot_maint_mention(false, false)
          mention += ' ^'
          
          send_alert = Alerts::Commands::SendMaintBlueBotSlackMessage.new(mention, channel)
          Job.create(send_alert)
        end

        # Send to prop channels as well
        channel = turns_for_property.property.update_slack_channel
        if !channel.nil? && channel != ''
          send_image = Alerts::Commands::SendMaintBlueBotWorkOrdersSlackImage.new(property_code, property_full_name, date, channel, completed_wos, percent_of_goal, incomplete_wos)
          Job.create(send_image)
  
          mention = turns_for_property.property.bluebot_blshift_mention(false)
          mention += ' ^'
          
          send_alert = Alerts::Commands::SendMaintBlueBotSlackMessage.new(mention, channel)
          Job.create(send_alert)
        end
      end
      
      def get_new_or_existing_metric(property, date)
        return Metric.where(property: property, date: date).first_or_initialize
      end

      def get_existing_metric(property, date)
        return Metric.where(property: property, date: date).first
      end
      
      def get_or_create_property(row)
        property_code = row[1].to_s.strip
        return Property.where(code: property_code).first_or_create!
      end

      def get_property(row)
        property_code = row[1].to_s.strip
        return Property.where(code: property_code).first
      end

      def get_new_or_existing_rent_change_reason(property, date, unit_type_code)
        return RentChangeReason.where(property: property, date: date, unit_type_code: unit_type_code).first_or_initialize
      end

      def get_new_or_existing_compliance_issue(date, property, issue)
        return ComplianceIssue.where(date: date, property: property, issue: issue).first_or_initialize
      end

      def get_new_or_existing_accounts_payable_compliance_issue(date, property, issue)
        return AccountsPayableComplianceIssue.where(date: date, property: property, issue: issue).first_or_initialize
      end

      def get_new_or_existing_conversions_for_agent(date, property, agent)
        return ConversionsForAgent.where(date: date, property: property, agent: agent).first_or_initialize
      end

      def get_new_or_existing_sales_for_agent(date, property, agent)
        return SalesForAgent.where(date: date, property: property, agent: agent).first_or_initialize
      end

      def get_new_or_existing_turns_for_property(date, property)
        return TurnsForProperty.where(date: date, property: property).first_or_initialize
      end

      def get_new_or_existing_incomplete_work_order(call_date, property, work_order)
        return IncompleteWorkOrder.where(call_date: call_date, property: property, work_order: work_order).first_or_initialize
      end

      def get_new_or_existing_costar_market_datum(date, property)
        return CostarMarketDatum.where(date: date, property: property).first_or_initialize
      end

      def get_new_or_existing_renewals_unknown_detail(date, property, yardi_code)
        return RenewalsUnknownDetail.where(date: date, property: property, yardi_code: yardi_code).first_or_initialize
      end

      def get_new_or_existing_collections_non_eviction_past20_detail(date, property, yardi_code)
        return CollectionsNonEvictionPast20Detail.where(date: date, property: property, yardi_code: yardi_code).first_or_initialize
      end

      def get_new_or_existing_average_rents_bedroom_detail(date, property, num_of_bedrooms)
        return AverageRentsBedroomDetail.where(date: date, property: property, num_of_bedrooms: num_of_bedrooms).first_or_initialize
      end

      def get_new_or_existing_comp_survey_by_bed_detail(date, property, num_of_bedrooms)
        return CompSurveyByBedDetail.where(date: date, property: property, num_of_bedrooms: num_of_bedrooms).first_or_initialize
      end

      def get_new_or_existing_collections_detail(date_time, property)
        return CollectionsDetail.where(date_time: date_time, property: property).first_or_initialize
      end

      def get_new_or_existing_collections_by_tenant_detail(date_time, property, tenant_code)
        return CollectionsByTenantDetail.where(date_time: date_time, property: property, tenant_code: tenant_code).first_or_initialize
      end
      

      def update_property_full_name(property, row)
        if row[30].nil? or row[30].to_s.strip.empty?
          property.full_name = property.code
        else
          property_full_name = row[30].to_s.strip
          property.full_name = property_full_name
        end

        property.save!
      end
      
      def assign_values_to_metric(row, metric)
        metric.date = get_date(row, 0)
        
        metric.number_of_units = get_decimal_from_string(row[2])
        metric.physical_occupancy = get_decimal_from_string(row[3])
        metric.cnoi = get_decimal_from_string(row[4])
        if metric.cnoi > 150
          metric.cnoi = 100
        end
        metric.trending_average_daily = get_decimal_from_string(row[5])
        metric.trending_next_month = get_decimal_from_string(row[6])
        metric.occupancy_average_daily = get_decimal_from_string(row[7])
        metric.occupancy_budgeted_economic = get_decimal_from_string(row[8])
        metric.occupancy_average_daily_30_days_ago = get_decimal_from_string(row[9])
        metric.average_rents_net_effective = get_decimal_from_string(row[10])
        metric.average_rents_net_effective_budgeted = get_decimal_from_string(row[11])
        metric.basis = get_decimal_from_string(row[12])
        metric.basis_year_to_date = get_decimal_from_string(row[13])
        if metric.basis_year_to_date > 150
          metric.basis_year_to_date = 100
        end
        metric.expenses_percentage_of_past_month = get_decimal_from_string(row[14])
        metric.expenses_percentage_of_budget = get_decimal_from_string(row[15])
        metric.renewals_number_renewed = get_decimal_from_string(row[16])
        metric.renewals_percentage_renewed = get_decimal_from_string(row[17])
        metric.collections_current_status_residents_with_last_month_balance = get_decimal_from_string(row[18])
        metric.collections_unwritten_off_balances = get_decimal_from_string(row[19])
        metric.collections_percentage_recurring_charges_collected = get_decimal_from_string(row[20])
        metric.collections_current_status_residents_with_current_month_balance = get_decimal_from_string(row[21])
        metric.collections_number_of_eviction_residents = get_decimal_from_string(row[22])
        metric.maintenance_percentage_ready_over_vacant = get_decimal_from_string(row[23])
        metric.maintenance_number_not_ready = get_decimal_from_string(row[24])
        metric.maintenance_turns_completed = get_decimal_from_string(row[25])
        metric.maintenance_open_wos = get_decimal_from_string(row[26])
        metric.rolling_30_net_sales = get_decimal_from_string(row[27])
        metric.rolling_10_net_sales = get_decimal_from_string(row[28])

        # Now set by separate spreadsheet
        if metric.property.code != Property.portfolio_code() && metric.property.type != "Team"
          metric.leases_attained = get_decimal_from_string(row[31])
          metric.leases_goal = get_decimal_from_string(row[32])
        end

        if row[33].nil? or row[33].to_s.strip.empty?
          metric.leases_alert_message = ''
        else
          metric.leases_alert_message = row[33]
        end
        metric.leases_attained_no_monies = get_decimal_from_string(row[34])
        metric.average_market_rent = get_decimal_from_string(row[35])
        if !metric.average_rents_net_effective.nil? && !metric.average_rents_net_effective_budgeted.nil? && metric.average_rents_net_effective_budgeted != 0
          metric.average_rent_delta_percent = (metric.average_rents_net_effective - metric.average_rents_net_effective_budgeted) / metric.average_rents_net_effective_budgeted * 100
        end
        metric.leases_last_24hrs = get_decimal_from_string(row[36])
        metric.renewals_unknown = get_decimal_from_string(row[37])
        metric.maintenance_vacants_over_nine_days = get_decimal_from_string(row[38])
        metric.average_rent_weighted_per_unit_specials = get_decimal_from_string(row[39])
        metric.average_rent_year_over_year_without_vacancy = get_decimal_from_string(row[40])
        metric.average_rent_year_over_year_with_vacancy = get_decimal_from_string(row[41])    
        metric.maintenance_total_open_work_orders = get_decimal_from_string(row[42])

        # Good data for concessions_per_unit and concessions_budgeted_per_unit started on 1/29/19
        metric.concessions_per_unit = get_decimal_from_string(row[43])
        metric.concessions_budgeted_per_unit = get_decimal_from_string(row[44])

        # AT/45 - average days vacant for any unit that has been vacant for more than 7 days
        metric.average_days_vacant_over_seven = get_decimal_from_string(row[45])

        # Used as budget for trending_average_daily
        # NOTE: Needs to be added back for latest in blueshift_updates branch
        # metric.budgeted_trended_occupancy = get_decimal_from_string(row[46])

        # AV/47 - # denied applications for the month
        metric.denied_applications_current_month = get_decimal_from_string(row[47])

        # AW/48 - # eviction residents with at least two months due
        metric.collections_eviction_residents_over_two_months_due = get_decimal_from_string(row[48])

        # AX/48 - # of residents that are month-to-month (MTM)
        metric.renewals_residents_month_to_month = get_decimal_from_string(row[49])

        # AY/49 - Projected CNOI (XX%)
        metric.projected_cnoi = get_decimal_from_string(row[50])

        # AZ/50 - YTD Renewal % (XX%)
        metric.renewals_ytd_percentage = get_decimal_from_string(row[51])
      end

      def assign_values_to_rent_change_reason(row, rent_change_reason)
        rent_change_reason.unit_type_code = row[2].to_s.strip
        rent_change_reason.old_market_rent = get_decimal_from_string(row[3])
        rent_change_reason.new_rent = get_decimal_from_string(row[4])
        if rent_change_reason.old_market_rent != 0
          rent_change_reason.percent_change = (rent_change_reason.new_rent - rent_change_reason.old_market_rent) / rent_change_reason.old_market_rent * 100.0
        end
        rent_change_reason.change_amount = rent_change_reason.new_rent - rent_change_reason.old_market_rent
        rent_change_reason.trigger = row[7].to_s.strip
        rent_change_reason.average_daily_occupancy_trend_30days_out = get_decimal_from_string(row[8])
        rent_change_reason.average_daily_occupancy_trend_60days_out = get_decimal_from_string(row[9])
        rent_change_reason.average_daily_occupancy_trend_90days_out = get_decimal_from_string(row[10])
        rent_change_reason.last_survey_days_ago = get_decimal_from_string(row[15])
        rent_change_reason.num_of_units = get_decimal_from_string(row[16])
        # row[17] - Old Market, Rent (Special Adjusted)
        # row[18] - 90 days, UT Exposure
        rent_change_reason.units_vacant_not_leased = get_decimal_from_string(row[19]).to_i
        rent_change_reason.units_on_notice_not_leased = get_decimal_from_string(row[20]).to_i
        rent_change_reason.last_three_rent = get_decimal_from_string(row[22]).to_i
      end

      def assign_values_to_compliance_issue(row, compliance_issue)
        compliance_issue.issue = row[2].to_s.strip
        compliance_issue.num_of_culprits = get_decimal_from_string(row[3])
        compliance_issue.culprits = row[4].to_s.strip
        compliance_issue.trm_notify_only = get_decimal_from_string(row[5]) == 1 ? true : false
      end

      def assign_values_to_accounts_payable_compliance_issue(row, compliance_issue)
        compliance_issue.issue = row[2].to_s.strip
        compliance_issue.num_of_culprits = get_decimal_from_string(row[3])
        compliance_issue.culprits = row[4].to_s.strip
      end

      # def assign_values_to_conversions_for_agent(row, conversions_for_agent)
      #   conversions_for_agent.prospects_30days = get_decimal_from_string(row[3])
      #   conversions_for_agent.conversion_30days = get_decimal_from_string(row[4])
      #   conversions_for_agent.conversion_365days = get_decimal_from_string(row[5])
      #   conversions_for_agent.close_30days = get_decimal_from_string(row[6])
      #   conversions_for_agent.close_365days = get_decimal_from_string(row[7])
      #   conversions_for_agent.decline_30days = get_decimal_from_string(row[8])
      #   conversions_for_agent.prospects_180days = get_decimal_from_string(row[9])
      #   conversions_for_agent.conversion_180days = get_decimal_from_string(row[10])
      #   conversions_for_agent.close_180days = get_decimal_from_string(row[11])
      #   conversions_for_agent.prospects_365days = get_decimal_from_string(row[12])
      # end

      def assign_leads_values_to_conversions_for_agent(row, conversions_for_agent)
        if conversions_for_agent.property.code == conversions_for_agent.agent
          conversions_for_agent.is_property_data = true
          conversions_for_agent.units = get_integer_from_string(row[3])
          conversions_for_agent.renewal_30days = get_decimal_from_string(row[7])
          conversions_for_agent.renewal_180days = get_decimal_from_string(row[8])
          conversions_for_agent.renewal_365days = get_decimal_from_string(row[9])
        else          
          conversions_for_agent.is_property_data = false
        end
        conversions_for_agent.prospects_30days = get_decimal_from_string(row[11])
        conversions_for_agent.prospects_180days = get_decimal_from_string(row[12])
        conversions_for_agent.prospects_365days = get_decimal_from_string(row[13])
        conversions_for_agent.shows_30days = get_decimal_from_string(row[15])
        conversions_for_agent.shows_180days = get_decimal_from_string(row[16])
        conversions_for_agent.shows_365days = get_decimal_from_string(row[17])
        conversions_for_agent.submits_30days = get_decimal_from_string(row[19])
        conversions_for_agent.submits_180days = get_decimal_from_string(row[20])
        conversions_for_agent.submits_365days = get_decimal_from_string(row[21])
        conversions_for_agent.declines_30days = get_decimal_from_string(row[22])
        conversions_for_agent.declines_180days = get_decimal_from_string(row[23])
        conversions_for_agent.declines_365days = get_decimal_from_string(row[24])
        conversions_for_agent.leases_30days = get_decimal_from_string(row[25])
        conversions_for_agent.leases_180days = get_decimal_from_string(row[26])
        conversions_for_agent.leases_365days = get_decimal_from_string(row[27])

        if conversions_for_agent.prospects_30days != 0 && conversions_for_agent.shows_30days != 0
          conversions_for_agent.conversion_30days = conversions_for_agent.shows_30days / conversions_for_agent.prospects_30days * 100.0   
          conversions_for_agent.close_30days = conversions_for_agent.submits_30days / conversions_for_agent.shows_30days * 100.0  
        else
          conversions_for_agent.conversion_30days = 0
          conversions_for_agent.close_30days = 0
        end
        if conversions_for_agent.prospects_180days != 0 && conversions_for_agent.shows_180days != 0
          conversions_for_agent.conversion_180days = conversions_for_agent.shows_180days / conversions_for_agent.prospects_180days * 100.0  
          conversions_for_agent.close_180days = conversions_for_agent.submits_180days / conversions_for_agent.shows_180days * 100.0 
        else
          conversions_for_agent.conversion_180days = 0
          conversions_for_agent.close_180days = 0
        end
        if conversions_for_agent.prospects_365days != 0 && conversions_for_agent.shows_365days != 0
          conversions_for_agent.conversion_365days = conversions_for_agent.shows_365days / conversions_for_agent.prospects_365days * 100.0 
          conversions_for_agent.close_365days = conversions_for_agent.submits_365days / conversions_for_agent.shows_365days * 100.0
        else
          conversions_for_agent.conversion_365days = 0
          conversions_for_agent.close_365days = 0
        end

        if conversions_for_agent.submits_30days != 0
          conversions_for_agent.decline_30days = conversions_for_agent.declines_30days / conversions_for_agent.submits_30days * 100   
        else
          conversions_for_agent.decline_30days = 0
        end
        if conversions_for_agent.submits_180days != 0
          conversions_for_agent.decline_180days = conversions_for_agent.declines_180days / conversions_for_agent.submits_180days * 100   
        else
          conversions_for_agent.decline_180days = 0
        end
        if conversions_for_agent.submits_365days != 0
          conversions_for_agent.decline_365days = conversions_for_agent.declines_365days / conversions_for_agent.submits_365days * 100   
        else
          conversions_for_agent.decline_365days = 0
        end

        # If Property data, set further metrics
        if conversions_for_agent.is_property_data
          metrics = conversions_for_agent.property_metrics()
          conversions_for_agent.num_of_leads_needed = metrics[:num_of_leads_needed]
        end
      end

      def assign_values_to_sales_for_agent(row, sales_for_agent)
        sales_for_agent.sales = get_decimal_from_string(row[3])
        sales_for_agent.goal = get_decimal_from_string(row[4])
        sales_for_agent.sales_prior_month = get_decimal_from_string(row[5])
        sales_for_agent.super_star_goal = get_decimal_from_string(row[6])
        sales_for_agent.goal_for_slack = get_decimal_from_string(row[7])
        sales_for_agent.agent_email = row[8].to_s
      end

      def assign_values_to_turns_for_property(row, turns_for_property)
        turns_for_property.turned_t9d = get_decimal_from_string(row[2])
        turns_for_property.total_vnr_9days_ago = get_decimal_from_string(row[3])
        if turns_for_property.total_vnr_9days_ago > 0
          turns_for_property.percent_turned_t9d = (turns_for_property.turned_t9d / turns_for_property.total_vnr_9days_ago) * 100
        elsif turns_for_property.turned_t9d >= 0
          turns_for_property.percent_turned_t9d = 100
        else
          turns_for_property.percent_turned_t9d = 0
        end
        turns_for_property.total_vnr = get_decimal_from_string(row[4])
        turns_for_property.wo_completed_yesterday = get_decimal_from_string(row[5])
        turns_for_property.wo_open_over_48hrs = get_decimal_from_string(row[6])
        turns_for_property.wo_percent_completed_t30 = get_decimal_from_string(row[7])
      end

      def assign_values_to_incomplete_work_order(row, incomplete_work_order)
        # Assumption: call_date, property, and work_order already set
        # Set / Update Data
        import_date = get_date(row, 0)
        if incomplete_work_order.latest_import_date.nil? || import_date >= incomplete_work_order.latest_import_date
          incomplete_work_order.latest_import_date = import_date
          incomplete_work_order.unit = row[2].to_s
          incomplete_work_order.brief_desc = row[6].to_s
          incomplete_work_order.reason_incomplete = row[7].to_s

          update_date = get_date(row, 5)
          if update_date && (incomplete_work_order.update_date.nil? || update_date >= incomplete_work_order.update_date)
            incomplete_work_order.update_date = update_date
          end  
        end
      end

      def assign_values_to_costar_market_datum(row, costar_market_datum)
        # Assumption: date and property already set
        # Set / Update Data
        costar_market_datum.submarket_percent_vacant = get_decimal_from_string(row[2])
        costar_market_datum.average_effective_rent = get_decimal_from_string(row[3])
        costar_market_datum.studio_effective_rent = get_decimal_from_string(row[4])
        costar_market_datum.one_bedroom_effective_rent = get_decimal_from_string(row[5])
        costar_market_datum.two_bedroom_effective_rent = get_decimal_from_string(row[6])
        costar_market_datum.three_bedroom_effective_rent = get_decimal_from_string(row[7])
        costar_market_datum.four_bedroom_effective_rent = get_decimal_from_string(row[8])
      end

      def assign_values_to_renewals_unknown_detail(row, renewals_unknown_detail)
        # Assumption: date, property, and yardi_code already set
        # Set / Update Data
        renewals_unknown_detail.tenant = row[3].to_s
        renewals_unknown_detail.unit = row[4].to_s
      end

      def assign_values_to_collections_non_eviction_past20_detail(row, collections_detail)
          # Assumption: date, property, and yardi_code already set
          # Set / Update Data
          collections_detail.tenant = row[3].to_s
          collections_detail.unit = row[4].to_s
          collections_detail.balance = get_decimal_from_string(row[5])
      end

      def assign_values_to_average_rents_bedroom_detail(row, average_rents_bedroom_detail)
        # Assumption: date, property, and num_of_bedrooms already set
        # Set / Update Data
        average_rents_bedroom_detail.net_effective_average_rent = get_decimal_from_string(row[3])
        average_rents_bedroom_detail.market_rent = get_decimal_from_string(row[4])
        average_rents_bedroom_detail.nom_of_new_leases = get_decimal_from_string(row[7])
        average_rents_bedroom_detail.num_of_renewal_leases = get_decimal_from_string(row[8])

        if average_rents_bedroom_detail.nom_of_new_leases > 0
          average_rents_bedroom_detail.new_lease_average_rent = get_decimal_from_string(row[5])
        end
        if average_rents_bedroom_detail.num_of_renewal_leases > 0
          average_rents_bedroom_detail.renewal_lease_average_rent = get_decimal_from_string(row[6])
        end
      end

      def assign_values_to_comp_survey_by_bed_detail(row, comp_survey_by_bed_detail)
        # Assumption: date, property, and yardi_code already set
        # Set / Update Data
        comp_survey_by_bed_detail.our_market_rent = get_decimal_from_string(row[3])
        comp_survey_by_bed_detail.comp_market_rent = get_decimal_from_string(row[4])
        comp_survey_by_bed_detail.our_occupancy = get_decimal_from_string(row[5])
        comp_survey_by_bed_detail.comp_occupancy = get_decimal_from_string(row[6])
        comp_survey_by_bed_detail.days_since_last_survey = get_decimal_from_string(row[7])
        comp_survey_by_bed_detail.survey_date = comp_survey_by_bed_detail.date - comp_survey_by_bed_detail.days_since_last_survey.days
      end

      def assign_values_to_collections_detail(row, collections_detail)
        # Assumption: date_time and property already set
        # Set / Update Data
        collections_detail.num_of_units = get_decimal_from_string(row[2])
        collections_detail.occupancy = get_decimal_from_string(row[3])
        collections_detail.total_charges = get_decimal_from_string(row[4])
        collections_detail.total_paid = get_decimal_from_string(row[5])
        collections_detail.total_payment_plan = get_decimal_from_string(row[6])
        collections_detail.total_evictions_owed = get_decimal_from_string(row[7])
        collections_detail.num_of_unknown = get_decimal_from_string(row[8])
        collections_detail.num_of_payment_plan = get_decimal_from_string(row[9])
        collections_detail.num_of_paid_in_full = get_decimal_from_string(row[10])
        collections_detail.num_of_evictions = get_decimal_from_string(row[11])
        collections_detail.paid_full_color_code = get_decimal_from_string(row[12])
        collections_detail.paid_full_with_pp_color_code = get_decimal_from_string(row[13])
        collections_detail.avg_daily_occ_adj = get_decimal_from_string(row[14])
        collections_detail.avg_daily_trend_2mo_adj = get_decimal_from_string(row[15])
        collections_detail.past_due_rents = get_decimal_from_string(row[16])
        collections_detail.covid_adjusted_rents = get_decimal_from_string(row[17])
      end

      def assign_values_to_collections_by_detail_detail(row, collections_by_tenant_detail)
        # Assumption: date_time, property, and tenant already set
        # Set / Update Data
        collections_by_tenant_detail.tenant_name = row[3].to_s
        collections_by_tenant_detail.unit_code = row[4].to_s
        collections_by_tenant_detail.total_charges = get_decimal_from_string(row[5])
        collections_by_tenant_detail.total_owed = get_decimal_from_string(row[6])

        if get_decimal_from_string(row[7]) == 1
          collections_by_tenant_detail.payment_plan = true
        else
          collections_by_tenant_detail.payment_plan = false
        end
        if get_decimal_from_string(row[8]) == 1
          collections_by_tenant_detail.eviction = true
        else
          collections_by_tenant_detail.eviction = false
        end

        collections_by_tenant_detail.mobile_phone = row[9].to_s
        collections_by_tenant_detail.home_phone = row[10].to_s
        collections_by_tenant_detail.office_phone = row[11].to_s

        collections_by_tenant_detail.email = row[12].to_s

        collections_by_tenant_detail.last_note = row[13].to_s

        # Is there a last note?
        if collections_by_tenant_detail.last_note.present? && collections_by_tenant_detail.last_note != ""
          prev_detail = CollectionsByTenantDetail.where("date_time < ?", collections_by_tenant_detail.date_time).where(property: collections_by_tenant_detail.property, tenant_code: collections_by_tenant_detail.tenant_code).order("date_time DESC").first
          # Is there a previous detail for this tenant?
          if prev_detail.present?
            # Has last_note_updated_at been set yet?  If not, this is the update
            if prev_detail.last_note_updated_at.nil?
              collections_by_tenant_detail.last_note_updated_at = collections_by_tenant_detail.date_time
            # If it has been set, let's look at last last_note for a change
            elsif prev_detail.last_note != collections_by_tenant_detail.last_note
              collections_by_tenant_detail.last_note_updated_at = collections_by_tenant_detail.date_time
            # Otherwise, keep existing (previous) value
            else
              collections_by_tenant_detail.last_note_updated_at = prev_detail.last_note_updated_at
            end
          # No previous detail, then starting value
          else
            collections_by_tenant_detail.last_note_updated_at = collections_by_tenant_detail.date_time
          end
        end

        if get_decimal_from_string(row[14]) == 1
          collections_by_tenant_detail.payment_plan_delinquent = true
        else
          collections_by_tenant_detail.payment_plan_delinquent = false
        end
      end

      def send_leasing_goal_slack_message(property, metric, date)
        unless metric.property.slack_channel.present?
          return
        end

        channel = metric.property.update_slack_channel

        unless Rails.env.test?
          # only send messages if after yesterday
          if date < Date.today - 1.day
            return
          end

#          return if slack_channel != '#360-test-channel'                  
        end

        if metric.leases_attained.nil? || metric.leases_goal.nil?
          return
        end

        # Set mention for slack messages
        mention = property.bluebot_leasing_mention
        
        month = date.strftime("%B")

        # lease_goal_for_the_month = '%0.f' % metric.leases_goal

        # leases_attained_num = metric.leases_attained
        # total_lease_goal_num = metric.leases_attained + metric.leases_goal
        # percent_of_goal_num = 0

        # # If total goal is <= zero, adjust attained and total goal, for bluebot graphic and messaging
        # if total_lease_goal_num <= 0
        #   if leases_attained_num >= total_lease_goal_num # attained >= total_goal, then (ABS(A-T)+1)/1
        #     leases_attained_num = (leases_attained_num - total_lease_goal_num).abs + 1
        #     total_lease_goal_num = 1
        #     percent_of_goal_num = leases_attained_num.to_f / total_lease_goal_num.to_f * 100.0
        #     leases_attained_num = leases_attained_num - 1
        #     total_lease_goal_num = 0
        #   else # attained < total_goal, then 0/ABS(T-A)
        #     leases_attained_num = 0
        #     total_lease_goal_num = (total_lease_goal_num - leases_attained_num).abs
        #     percent_of_goal_num = leases_attained_num.to_f / total_lease_goal_num.to_f * 100.0    
        #   end
        # else # total lease goal > 0
        #   percent_of_goal_num = leases_attained_num.to_f / total_lease_goal_num.to_f * 100.0
        # end

        leases_attained_num = metric.leases_attained_adjusted
        total_lease_goal_num = metric.total_lease_goal_adjusted
        percent_of_goal_num = metric.percent_of_lease_goal_adjusted

        leases_attained = '%0.f' % leases_attained_num
        total_lease_goal = '%0.f' % total_lease_goal_num
        percent_of_goal = '%0.f' % percent_of_goal_num

        # Find the delta from yesterday
        leases_attained_delta = nil
        metric_yesterday = Metric.where(property: property, date: date - 1.day).first
        if metric_yesterday.present? && metric_yesterday.leases_attained_adjusted.present?
          
          leases_attained_num_yesterday = metric_yesterday.leases_attained_adjusted
          # total_lease_goal_num_yesterday = metric_yesterday.total_lease_goal_adjusted

          delta = leases_attained_num - leases_attained_num_yesterday
          if delta == 0
            leases_attained_delta = '0'
            leases_attained_yesterday = '%0.f' % leases_attained_num_yesterday            
          elsif delta > 0
            leases_attained_delta = '+' + '%0.f' % delta
          else
            leases_attained_delta = '%0.f' % delta            
          end
        end

        alert_message = ''
        unless metric.leases_alert_message.nil? || metric.leases_alert_message.empty?
          alert_message = "\n\n`#{metric.leases_alert_message}`"

          # No longer sending to maint channels, since we have a weekly turns graphic now
          # Also send to maint-<propname>
          # maint_message = "@channel: #{alert_message}"
          # maint_channel = metric.property.slack_channel_for_maint
          # # Remove @channel or @user, if test
          # if maint_channel.include? 'test'
          #   maint_message.sub! '@', ''
          # end
          # send_alert = Alerts::Commands::SendSlackMessage.new(maint_message, maint_channel)
          # Job.create(send_alert) 
        end

        leases_attained_no_monies_message = ''
        leases_attained_no_monies_message_for_image = ''
        unless metric.leases_attained_no_monies.nil? || metric.leases_attained_no_monies <= 0
          leases_attained_no_monies_message = "However, *#{'%0.f' % metric.leases_attained_no_monies}* of your leases show no monies collected!"
          leases_attained_no_monies_message_for_image = "However, <strong>#{'%0.f' % metric.leases_attained_no_monies}</strong> of your leases show no monies collected!"
        end

        # OLD CODE, if leases_goal == 0
        # message = "#{slack_target}: Congratulations! You hit your sales goal for the month. Now's the time to push sales even harder to become an outstanding property (and to build cushion for any unexpected moveouts). #{leases_attained_no_monies_message}#{alert_message}"

        # OLD CODE, if leases_goal < 0
        # message = "#{slack_target}: Wow you've gotten *#{'%0.f' % lease_goal_for_the_month.to_f.abs}* lease(s) above your sales goal. Keep the momentum going! #{leases_attained_no_monies_message}#{alert_message}"

        if percent_of_goal_num >= 100
          message = "#{mention}: Congratulations! You hit your sales goal for the month. Now's the time to push sales even harder to become an outstanding property (and to build cushion for any unexpected moveouts). #{leases_attained_no_monies_message}#{alert_message}"

          if Rails.env.test?
            channel = '#test'
            leases_attained_no_monies_message_for_image = "However, <strong>3</strong> of your leases show no monies collected!"
          end

          # Force zero, to ignore
          num_of_days_with_no_leases = 0 
          leases_message = "Congratulations! Keep up the momentum to get a head start for next month! #{leases_attained_no_monies_message_for_image}"
          send_image = Alerts::Commands::SendSlackImage.new(metric.property.code, metric.property.full_name, date, channel, percent_of_goal, leases_attained, total_lease_goal, leases_message, leases_attained_delta, num_of_days_with_no_leases)
            
          # *** TEST LOCALLY in Slack ***
          # send_image.perform
          Job.create(send_image)

          # Alert everyone, since @channel doesn't work in image upload
          message = "#{mention}: ^#{alert_message}"

          send_alert = Alerts::Commands::SendSlackMessage.new(message, channel)
          Job.create(send_alert) 

          # TODO: Remove after we have teams again
          if metric.property.code == Property.portfolio_code()
            channel = '#bluestone-team-leasing'
            send_image = Alerts::Commands::SendSlackImage.new(metric.property.code, metric.property.full_name, date, channel, percent_of_goal, leases_attained, total_lease_goal, leases_message, leases_attained_delta, num_of_days_with_no_leases)
            Job.create(send_image)
            send_alert = Alerts::Commands::SendSlackMessage.new(message, channel)
            Job.create(send_alert) 
          end
        else
          leases_attained_no_monies_message = ''
          leases_attained_no_monies_message_for_image = ''
          unless metric.leases_attained_no_monies.nil? || metric.leases_attained_no_monies <= 0
            leases_attained_no_monies_message = "But *#{'%0.f' % metric.leases_attained_no_monies}* of those show no monies collected!"
            leases_attained_no_monies_message_for_image = "Note: <strong>#{'%0.f' % metric.leases_attained_no_monies}</strong> of your leases show no monies collected!"
          end
          
          leases_in_last_four_days_message = ''
          leases_in_last_four_days_message_for_image = ''
          leases_in_last_four_days = 0.0
          value_one = leases_attained_in_one_day(metric.property, date - 3.days, nil)
          unless value_one.nil? 
            leases_in_last_four_days += value_one
          end
          value_two = leases_attained_in_one_day(metric.property, date - 2.days, nil)
          unless value_two.nil?
            leases_in_last_four_days += value_two
          end
          value_three = leases_attained_in_one_day(metric.property, date - 1.day, nil)
          unless value_three.nil?
            leases_in_last_four_days += value_three
          end
          value_four = leases_attained_in_one_day(metric.property, date, metric)
          unless value_four.nil? 
            leases_in_last_four_days += value_four
          end
          unless value_one.nil? && value_two.nil? && value_three.nil? && value_four.nil?
            leases_in_last_four_days_message = " (You've leased net *#{'%0.f' % leases_in_last_four_days}* in the last four days.)"
            leases_in_last_four_days_message_for_image = "(You've leased net <strong>#{'%0.f' % leases_in_last_four_days}</strong> in the last four days.)"
          end

          message = "#{mention}: Your leasing goal for *#{month}* is *#{total_lease_goal}* and you have leased *#{leases_attained}* so far. #{leases_attained_no_monies_message} You are *#{percent_of_goal}%* towards achieving your goal.#{leases_in_last_four_days_message} #{alert_message}"

          if Rails.env.test?
            channel = '#test'
            leases_in_last_four_days_message_for_image = "(You've leased net <strong>6</strong> in the last four days.)<br />Note: <strong>3</strong> of your leases show no monies collected!"
          end

          num_of_days_with_no_leases = num_of_days_of_no_leases(metric.property, date)
          puts "#{num_of_days_with_no_leases} days with no leases"

          leases_message = "#{leases_in_last_four_days_message_for_image}<br />#{leases_attained_no_monies_message_for_image}"
          if num_of_days_with_no_leases >= 4
            leases_message = "#{leases_attained_no_monies_message_for_image}"
          end

          send_image = Alerts::Commands::SendSlackImage.new(metric.property.code, metric.property.full_name, date, channel, percent_of_goal, leases_attained, total_lease_goal, leases_message, leases_attained_delta, num_of_days_with_no_leases)          
          # *** TEST LOCALLY in Slack ***
          # send_image.perform
          Job.create(send_image)

          # Alert everyone, since @channel doesn't work in image upload
          message = "#{mention}: ^#{alert_message}"

          send_alert = Alerts::Commands::SendSlackMessage.new(message, channel)
          Job.create(send_alert) 

          # TODO: Remove after we have teams again
          if metric.property.code == Property.portfolio_code()
            channel = '#bluestone-team-leasing'
            send_image = Alerts::Commands::SendSlackImage.new(metric.property.code, metric.property.full_name, date, channel, percent_of_goal, leases_attained, total_lease_goal, leases_message, leases_attained_delta, num_of_days_with_no_leases)          
            Job.create(send_image)
            send_alert = Alerts::Commands::SendSlackMessage.new(message, channel)
            Job.create(send_alert) 
          end
        end 
      end

      def send_red_bot_slack_alert_image(channel, title, image_filename)
        # channel = update_slack_channel(slack_channel)
        # day_of_the_week = Date.today.strftime("%A")
        # if day_of_the_week != 'Monday'
        #   channel.sub! 'prop', 'test' # TODO: Remove, if no longer testing
        # else
        #   channel.sub! 'test', 'prop' # TODO: Remove, if no longer testing
        # end

        send_alert = 
          Alerts::Commands::SendRedBotSlackImage.new(channel, title, image_filename, false)
        Job.create(send_alert)  
      end

      def send_red_bot_slack_alert(message, channel)
        # channel = update_slack_channel(slack_channel)
        # day_of_the_week = Date.today.strftime("%A")
        # if day_of_the_week != 'Monday'
        #   channel.sub! 'prop', 'test' # TODO: Remove, if no longer testing
        # else
        #   channel.sub! 'test', 'prop' # TODO: Remove, if no longer testing
        # end

        # Remove @channel or @user, if test
        if channel.include? 'test'
          message.sub! '@', ''
        end
        
        send_alert = 
          Alerts::Commands::SendRedBotSlackMessage.new(message, channel)
        Job.create(send_alert)   
      end

      def send_corp_red_bot_slack_alert(message, channel)
        # Remove @channel or @user, if test
        if channel.include? 'test'
          message.sub! '@', ''
        end
        
        send_alert = 
          Alerts::Commands::SendCorpRedBotSlackMessage.new(message, channel)
        Job.create(send_alert)   
      end

      def leases_attained_in_one_day(property, date_two, imported_metric)
          metric_on_date_two = Metric.where(property: property, date: date_two).first
          if metric_on_date_two.nil?
            metric_on_date_two = imported_metric
          end
          metric_on_date_one = Metric.where(property: property, date: date_two - 1.day).first

          if date_two.mday == 1 || (date_two.mday == 2 && (metric_on_date_one.nil? || metric_on_date_one.leases_attained.nil?))
            unless metric_on_date_two.nil? || metric_on_date_two.leases_attained.nil?
              return metric_on_date_two.leases_attained.to_f
            else
              return nil
            end
          end

          unless metric_on_date_one.nil? || metric_on_date_one.leases_attained.nil? || metric_on_date_two.nil? || metric_on_date_two.leases_attained.nil?
            return metric_on_date_two.leases_attained.to_f - metric_on_date_one.leases_attained.to_f
          else
            return nil
          end
      end

      def num_of_days_of_no_leases(property, date)
        # Look back 1 month
        metrics_with_no_leases = Metric.where(property: property)
                                       .where("date > ?", date - 31.days)
                                       .where("date <= ?", date)
                                       .order("date DESC")

        days_count = 0
        metrics_with_no_leases.each do |metric|
          count = leases_attained_in_one_day(property, metric.date, nil)
          if !count.nil? && count <= 0
            days_count += 1
          else
            return days_count
          end
        end

        return days_count
      end

      def message_for_compliance_issues(property, property_manager_usernames, date, issues_ordered)
        message = "#{property.leasing_mention} #{property.talent_resource_manager_mention(nil)}: ^ \n\n"

        manager_slack_usernames = 'Manager'
        if !property_manager_usernames.empty?
          manager_slack_usernames = property_manager_usernames
        end
        message += "*#{manager_slack_usernames}, please respond to this notification in a thread below and tag your TRM (Talent Resource Manager) with your response.*\n\n"

        # issues_count_hash = Hash.new
        message += "```"
        issues_ordered.each do |c|
          message += "#{c.num_of_culprits.round} #{c.issue}\n"
          # if issues_count_hash[c.issue].nil?
          #   issues_count_hash[c.issue] = 1
          # else
          #   issues_count_hash[c.issue] += 1
          # end
        end
        message += "```"

        # issues_count_hash.each { |key, value|
        #   message += "*#{value} #{key}*\n"
        # }

        unless Property.all_blacklist_codes().include?(property.code)
          message += "\nView details and fix it now! -> #{@root_url}/compliance_issues?property_id=#{property.id}&date=#{date}\n"
        end

        return message
      end

      def message_for_trm_compliance_issues(property, mention, issues_ordered)
        property_name = property.full_name
        if property_name.nil?
          property_name = property.code
        end
        message = "#{mention} *#{property_name}*: TRM Only Compliance Issues\n\n"

        # issues_count_hash = Hash.new
        message += "```"
        issues_ordered.each do |c|
          message += "#{c.num_of_culprits.round} #{c.issue}: #{c.culprits}\n"
        end
        message += "```"

        return message
      end

      def check_for_compliance_inaction(property, property_manager_usernames, issues_ordered, issues_ordered_last_week, issues_ordered_14_days_ago, issues_ordered_21_days_ago, issues_ordered_28_days_ago)
        channel = property.update_slack_channel
        # channel.sub! 'prop', 'test' # TODO: Remove, if going live

        # Remove blacklisted current issues
        # Add culprits as an array to hash
        issues_culprits_hash = Hash.new
        issues_ordered.each do |c|
          unless c.inaction_issue_blacklisted?
            issues_culprits_hash[c.issue] = c.culprits.split(";")
          end
        end

        # Remove blacklisted last week issues
        # Add culprits as an array to hash
        issues_culprits_last_week_hash = Hash.new
        issues_ordered_last_week.each do |c|
          unless c.inaction_issue_blacklisted? || c.inaction_issue_14_days? || c.inaction_issue_21_days? || c.inaction_issue_28_days?
            issues_culprits_last_week_hash[c.issue] = c.culprits.split(";")
          end
        end

        # Remove blacklisted 2 weeks ago issues
        # Add culprits as an array to hash
        issues_culprits_14_days_ago_hash = Hash.new
        issues_ordered_14_days_ago.each do |c|
          unless c.inaction_issue_blacklisted? || !c.inaction_issue_14_days?
            issues_culprits_14_days_ago_hash[c.issue] = c.culprits.split(";")
          end
        end

        # Remove blacklisted 2 weeks ago issues
        # Add culprits as an array to hash
        issues_culprits_21_days_ago_hash = Hash.new
        issues_ordered_21_days_ago.each do |c|
          unless c.inaction_issue_blacklisted? || !c.inaction_issue_21_days?
            issues_culprits_21_days_ago_hash[c.issue] = c.culprits.split(";")
          end
        end

        # Remove blacklisted 4 weeks ago issues
        # Add culprits as an array to hash
        issues_culprits_28_days_ago_hash = Hash.new
        issues_ordered_28_days_ago.each do |c|
          unless c.inaction_issue_blacklisted? || !c.inaction_issue_28_days?
            issues_culprits_28_days_ago_hash[c.issue] = c.culprits.split(";")
          end
        end

        issues_culprits_matched_hash = Hash.new

        issues_culprits_hash.each { |key, value|
          # Compare current issues to issues last week
          issue_culprits_last_week = issues_culprits_last_week_hash[key]
          unless issue_culprits_last_week.nil?
            matched_culprits = value & issue_culprits_last_week
            if !matched_culprits.nil? && matched_culprits.length > 0
              issues_culprits_matched_hash[key] = matched_culprits
            end
          end

          # Compare current issues to issues 14 days ago
          issue_culprits_14_days_ago = issues_culprits_14_days_ago_hash[key]
          unless issue_culprits_14_days_ago.nil?
            matched_culprits = value & issue_culprits_14_days_ago
            if !matched_culprits.nil? && matched_culprits.length > 0
              issues_culprits_matched_hash[key] = matched_culprits
            end
          end

          # Compare current issues to issues 21 days ago
          issue_culprits_21_days_ago = issues_culprits_21_days_ago_hash[key]
          unless issue_culprits_21_days_ago.nil?
            matched_culprits = value & issue_culprits_21_days_ago
            if !matched_culprits.nil? && matched_culprits.length > 0
              issues_culprits_matched_hash[key] = matched_culprits
            end
          end

          # Compare current issues to issues 28 days ago
          issue_culprits_28_days_ago = issues_culprits_28_days_ago_hash[key]
          unless issue_culprits_28_days_ago.nil?
            matched_culprits = value & issue_culprits_28_days_ago
            if !matched_culprits.nil? && matched_culprits.length > 0
              issues_culprits_matched_hash[key] = matched_culprits
            end
          end
        }

        if issues_culprits_matched_hash.length > 0
          message = "#{property_manager_usernames}: ^\n"
          issues_culprits_matched_hash.each { |key, value|
            message += "*#{key}:* `#{value.join(", ")}`\n"
          }
   
          if property.manager_strikes < 3
            property.manager_strikes += 1
            property.save!
          end

          image_filename = 'redbot_compliance_inaction_strike1_alert_image.png'
          if property.manager_strikes == 2
            image_filename = 'redbot_compliance_inaction_strike2_alert_image.png'
          elsif property.manager_strikes > 2
            image_filename = 'redbot_compliance_inaction_strike3_alert_image.png'
          end

          @logger.debug "Compliance Inaction Alert Message: #{message}"

          if channel.include? 'test'
            message.sub! '@', ''
          end

          send_red_bot_slack_alert_image(channel, '!!COMPLIANCE INACTION!!', image_filename)
          send_red_bot_slack_alert(message, channel)
        end

      end

      # -------
      # HELPERS
      # -------

      def get_date(row, column)
        if row[column].is_a? Date
          return row[column]
        end

        if row[column].is_a? String
          if row[column].include? "/"
            return Date.strptime(row[column], "%m/%d/%Y")
          elsif row[column].include? "-"
            return Date.strptime(row[column], "%m-%d-%Y")
          end
        end

        return nil
      end


      def get_decimal_from_string(value)
        if value.nil?
          return BigDecimal(0)
        elsif value.is_a? String and value.strip.empty?
          return BigDecimal(0)
        elsif value.is_a? String
          # Remove all non-digit characters, other than '.' and '-'
          value = value.scan(/[\d.-]+/).join
          return value.to_d 
        elsif value.is_a? Array
          new_value = value.join("")
          new_value = new_value.scan(/[\d.-]+/).join
          return new_value.to_d
        else 
          return value.to_d
        end
      end

      def get_integer_from_string(value)
        if value.nil?
          value = 0
        elsif value.is_a? String and value.strip.empty?
          value = 0
        elsif !value.is_a? String
          return value
        end

        return value.to_i
      end

      def number(value)
        number_with_precision(value, precision: 0, strip_insignificant_zeros: true)  
      end
  
    end
  end
end
