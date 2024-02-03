require 'httparty'
require 'bigdecimal'
include ActionView::Helpers::NumberHelper

# task :property_inspection_alerts => :environment do
#   # day_of_the_week = Date.today.strftime("%A")
#   # unless day_of_the_week == 'Monday'
#   #   exit()
#   # end

#   check_property_inspection_alerts  
# end

task :check_property_inspections => :environment do  
  check_property_inspection_alerts_and_creation_dates  
end

# task :comment_notifier => :environment do  
#   check_for_new_or_updated_comments  
# end

task :monthly_leasing_stars => :environment do 
  # Only should run on the 1st of the month
  if Date.today.day == 1
    puts "Task monthly_leasing_stars called"
    send_monthly_leasing_stars()
  end  
end

task :test_monthly_leasing_stars => :environment do 
  send_monthly_leasing_stars()
end

task :find_compliance_stars => :environment do 
  # Only should run on the Tuesdays
  if Date.today.wday == 2
    puts "Task send_compliance_stars called"
    send_compliance_stars  
  end
end

task :test_find_compliance_stars => :environment do 
  puts "Task send_compliance_stars called"
  send_compliance_stars  
end


task :check_data_for_today => :environment do 
  puts "Task check_data_for_today called"
  check_for_missing_data_today  
end

task :reprocess_druid_stats => :environment do
  puts "reprocess_druid_stats called"
  reprocess_druid_stats()
end

task :reimport_druid_stats => :environment do
  puts "reimport_druid_stats called"
  reimport_druid_stats()
end

task :backfill_process_leads_needed_for_properties => :environment do
  puts "backfill_process_leads_needed_for_properties called"
  backfill_process_leads_needed_for_properties()
end

task :backfill_blueshift_archived_failure_reasons => :environment do
  puts "backfill_blueshift_archived_failure_reasons called"
  backfill_blueshift_archived_failure_reasons()
end

task :reprocess_blueshift_trigger_values => :environment do
  puts "reprocess_blueshift_trigger_values called"
  BlueShift.find_each do |blue_shift|
    value = Properties::Commands::CheckBlueShiftRequirement.blueshift_required_for_basis_value?(blue_shift.property, blue_shift.metric.date)
    blue_shift.basis_triggered_value = value != -1 ? value : nil
    value = Properties::Commands::CheckBlueShiftRequirement.blueshift_required_for_trending_average_daily_value?(blue_shift.property, blue_shift.metric.date)
    blue_shift.trending_average_daily_triggered_value = value != -1 ? value : nil
    value = Properties::Commands::CheckBlueShiftRequirement.blueshift_required_for_physical_occupancy_value?(blue_shift.property, blue_shift.metric.date)
    blue_shift.physical_occupancy_triggered_value = value != -1 ? value : nil
    blue_shift.save(validate: false)
  end

  update_property_blueshift_statuses()
end

task :reprocess_property_blueshift_statuses => :environment do
  puts "reprocess_property_blueshift_statuses called"

  update_property_blueshift_statuses()
end

task :reprocess_property_trm_blueshift_statuses => :environment do
  puts "reprocess_property_trm_blueshift_statuses called"

  update_property_trm_blueshift_statuses()
end

# task :update_open_positions_google => :environment do
#   puts "update_open_positions_google called"

#   update_open_positions_via_google_sheet()
# end

task :get_all_workable_jobs_and_activities => :environment do
  puts "get_all_workable_jobs_and_activities called"

  get_all_workable_jobs_and_activities()
end

task :update_property_units => :environment do
  puts "update_property_units called"

  update_all_property_units_from_yardi()
end

task :check_for_calendar_events => :environment do
  puts "check_for_calendar_events called"

  check_for_calendar_events()
end

task :update_ultipro_employee_data => :environment do
  puts "update_ultipro_employee_data called"

  update_ultipro_employee_data()
end

task :send_open_workable_jobs_to_slack => :environment do
  # Only run on Thursdays
  if Date.today.wday == 4
    puts "send_open_workable_jobs_to_slack called"
    send_open_workable_jobs_to_slack()
  end
end

task :test_send_open_workable_jobs_to_slack => :environment do
  puts "send_open_workable_jobs_to_slack called"
  send_open_workable_jobs_to_slack()
end

task :check_monthly_maint_inspections => :environment do
  puts "check_monthly_maint_inspections called"
  check_monthly_maint_inspections()
end

task :test_sending_turns_for_properties => :environment do
  puts "test_sending_turns_for_properties called"
  test_sending_turns_for_properties()
end

task :test_sending_leasing_goals => :environment do 
  puts "test_sending_leasing_goals called"
  test_sending_leasing_goals()
end

task :test_sending_leasing_goal_slack_messages => :environment do 
  puts "test_sending_leasing_goals called"
  test_sending_leasing_goal_slack_messages()
end

private 

def update_ultipro_employee_data
  update_person_details = Ultipro::Commands::PersonDetails.new
  update_person_details.perform

  update_employment_details = Ultipro::Commands::EmploymentDetails.new
  update_employment_details.perform

  # Update jobs with employees
  jobs = WorkableJob.where.not(hired_candidate_name: nil).where.not(hired_at: nil)
  puts "#{jobs.count} Hired Jobs found"
  jobs.each do |job|
    if job.hired_candidate_name.present?
      # Make full name lowercase, to match workable_name, which is also set lowercase (see Employee.rb)
      hired_candidate_full_name = job.hired_candidate_name.downcase
      if job.employee_first_name_override.present? && job.employee_last_name_override.present?
        hired_candidate_full_name = "#{job.employee_first_name_override.downcase} #{job.employee_last_name_override.downcase}"
      end
      employee = Employee.where(workable_name: hired_candidate_full_name).where("date_in_job > ?", job.hired_at - 2.month).where("date_in_job < ?", job.hired_at + 2.month).first                         
      if employee.present?
        job.employee = employee
        job.employee_date_in_job = employee.date_in_job
        job.employee_date_last_worked = employee.date_last_worked
        job.employee_updated_at = DateTime.now
        job.save
        puts "A Job's Employee was added/updated for #{hired_candidate_full_name}"
      else  
        job.employee = nil
        job.employee_date_in_job = nil
        job.employee_date_last_worked = nil
        job.employee_updated_at = nil
        job.save
        puts "NO MATCH for hired Workable candidate: \"#{hired_candidate_full_name}\" (Job State = #{job.state})"
      end
    else  
      puts "MISSING hired_candidate_name for job.  Can't map Employee."
      job.employee = nil
      job.employee_date_in_job = nil
      job.employee_date_last_worked = nil
      job.employee_updated_at = nil
      job.save
    end
  end
end

def update_all_property_units_from_yardi
  service = Yardi::Voyager::Api::Units.new
  properties = Property.properties.where(active: true).where.not(code: Property.portfolio_code())
  properties.each do |prop|
    next if prop.code.downcase.include? "Office"
    begin
      puts "Calling getUnits for " + prop.code 
      units_data = service.getUnits(prop.code)
    rescue => e
      Airbrake.notify(e, error_message: "Updating Property Units failed for #{prop.code}")
    end

    next if units_data.nil?
    puts "Processing units_data for " + prop.code 
    units_data.each do |unit_data|
      PropertyUnit.import_yardi_unit_data(prop, unit_data)
    end
    puts "Property Units updated for #{prop.code}"
  end
end

def get_all_workable_jobs_and_activities
  # NOTE: requires ENV variable WORKABLE_API_AUTH_TOKEN

  # Import All, direct-referencing jobs
  update_workable_jobs = Workable::Commands::Jobs.new(add_reposts: false)
  update_workable_jobs.perform

  # Import All, Including reposts referencing other, direct-referencing jobs
  update_workable_jobs = Workable::Commands::Jobs.new(add_reposts: true)
  update_workable_jobs.perform

  jobs_exist = false

  # Update All Open jobs
  open_states = ["published", "closed"]
  workable_jobs = WorkableJob.where(state: open_states).order("job_created_at DESC")
  if workable_jobs.count > 0
    jobs_exist = true
    puts "Cobalt Recruiting: Updating Activities for #{workable_jobs.count} OPEN (published & closed) Jobs."
  end
  workable_jobs.each do |job|
    update_workable_job_activities = Workable::Commands::JobActivities.new(workable_job: job)
    update_workable_job_activities.perform
  end

  # Update ALL Closed jobs
  open_states = ["published", "closed"]
  workable_jobs = WorkableJob.where.not(state: open_states).order("job_created_at DESC")
  if workable_jobs.count > 0
    jobs_exist = true
    puts "Cobalt Recruiting: Updating Activities for #{workable_jobs.count} NOT OPEN (NOT published & NOT closed), LAST MEMBER ACTIVITY > 60 Days Ago Jobs OR Not Set Yet."
  end 
  workable_jobs.each do |job|
    update_workable_job_activities = Workable::Commands::JobActivities.new(workable_job: job)
    update_workable_job_activities.perform
  end

  # Data Import Record
  new_record = DataImportRecord.apiJSON(
    source: DataImportRecordSource::WORKABLE, 
    data_date: nil, 
    data_datetime: nil, 
    title: DataImportRecordWorkableJSONTitle::JobsActivities)
  new_record.data_imported = jobs_exist
  new_record.save!
  new_record.sendNoficationToSlack()
end

def send_open_workable_jobs_to_slack
  # Pull All Open Portfolio jobs
  workable_jobs = WorkableJob.where(state: "published", can_post: true, new_property: false, is_duplicate: false).where('lower(code) = ?', Property.portfolio_code.downcase).order("lower(title) ASC")
  company_title_sent = false
  if workable_jobs.count > 0
    company_title_sent = true
    message = "\n*360 JOBS*"
    send_bluebot_alert(message, '#internal-opportunities')
  end
  workable_jobs.each do |job|
    message = "TITLE: *#{job.title}*"
    if job.application_url.present?
      message += "\nURL: `#{job.application_url}`"
    else  
      message += ""
    end
    send_bluebot_alert(message, '#internal-opportunities')
  end

  # Pull All Open Team jobs
  team_codes = Team.where(active: true).order("code ASC").pluck('code')
  codes = team_codes.map do |code| 
    code.downcase
  end
  workable_jobs = WorkableJob.where(state: "published", can_post: true, new_property: false, is_duplicate: false).where('lower(code) IN (?)', codes).order("lower(code) ASC, lower(title) ASC")
  if workable_jobs.count > 0 && !company_title_sent
    message = "\n*360 JOBS*"
    send_bluebot_alert(message, '#internal-opportunities')
  end
  workable_jobs.each do |job|
    message = "TITLE: *#{job.title}*" 
    message += "\nTEAM: *#{job.property.code}*"
    if job.application_url.present?
      message += "\nURL: `#{job.application_url}`"
    else  
      message += ""
    end
    send_bluebot_alert(message, '#internal-opportunities')
  end

  # Pull All Open Property jobs
  property_codes = Property.properties.where(active: true).where.not(code: Property.portfolio_code).pluck('code')
  codes = property_codes.map do |code| 
    code.downcase
  end
  workable_jobs = WorkableJob.where(state: "published", can_post: true, new_property: false, is_duplicate: false).where('lower(code) IN (?)', codes).order("lower(code) ASC, lower(title) ASC")
  property_title_sent = false
  if workable_jobs.count > 0
    property_title_sent = true
    message = "\n*PROPERTY JOBS*"
    send_bluebot_alert(message, '#internal-opportunities')
  end
  workable_jobs.each do |job|
    message = "TITLE: *#{job.title}*" 
    message += "\nPROPERTY: *#{job.property.full_name}*"
    message += "\nLOCATION: *#{job.property.city}, #{job.property.state}*"
    if job.application_url.present?
      message += "\nURL: `#{job.application_url}`"
    else  
      message += ""
    end
    send_bluebot_alert(message, '#internal-opportunities')
  end

  # Pull All Open New Property jobs
  workable_jobs = WorkableJob.where(state: "published", can_post: true, new_property: true, is_duplicate: false).order("lower(code) ASC, lower(title) ASC")
  if workable_jobs.count > 0 && !property_title_sent
    message = "\n*PROPERTY JOBS*"
    send_bluebot_alert(message, '#internal-opportunities')
  end
  workable_jobs.each do |job|
    message = "TITLE: *#{job.title}*" 
    if job.new_property
      message += "\nPROPERTY: `NEW`"
    end
    message += "\nTEAM: *#{job.property.code}*"
    if job.application_url.present?
      message += "\nURL: `#{job.application_url}`"
    else  
      message += ""
    end
    send_bluebot_alert(message, '#internal-opportunities')
  end
end

# def update_open_positions_via_google_sheet 
#   service = Sheet.new
#   spreadsheet = service.spreadsheet('17nqQ75oJ66Y0omTAI88uS-RXR8VwJ1_Q_Bicb-uJGy8')
#   worksheet = spreadsheet.worksheets.first
#   puts worksheet.rows
# end

def update_property_blueshift_statuses
  first_active_property = Property.properties.where(active: true, is_duplicate: false).first
  if !first_active_property.nil?
    todays_metric = Metric.where(property: first_active_property, date: Date.today).where(main_metrics_received: true).first
    if todays_metric.nil?
      latest_metric = Metric.where(property: first_active_property).where(main_metrics_received: true).order("date DESC").first
      if !latest_metric.nil?
        Property.properties.where(active: true).each do |p|
          Property.update_property_blue_shift_status(p, latest_metric.date, false)
        end
      end
    else
      Property.properties.where(active: true).each do |p|
        Property.update_property_blue_shift_status(p, todays_metric.date, false)
      end
    end
  end
end

def update_property_trm_blueshift_statuses
  first_active_property = Property.properties.where(active: true).first
  if !first_active_property.nil?
    todays_metric = Metric.where(property: first_active_property, date: Date.today).where(main_metrics_received: true).first
    if todays_metric.nil?
      latest_metric = Metric.where(property: first_active_property).where(main_metrics_received: true).order("date DESC").first
      if !latest_metric.nil?
        Property.properties.where(active: true).each do |p|
          Property.update_property_trm_blue_shift_status(p, latest_metric.date, false)
        end
      end
    else
      Property.properties.where(active: true).each do |p|
        Property.update_property_trm_blue_shift_status(p, todays_metric.date, false)
      end
    end
  end
end

def send_monthly_leasing_stars
  end_of_last_month = Date.today.last_month.end_of_month
  findMonthlyStarsCmd = Leasing::Commands::FindMonthlyStars.new(end_of_month_date: end_of_last_month)
  data = findMonthlyStarsCmd.perform

  leasing_stars = data[:leasing_stars]
  if leasing_stars.count > 0
    channel = "#leasing"
    puts "Bluebot ImageMonthlyLeasingStars graphic sent to #{channel} channel"
    send_image = Alerts::Commands::SendSlackImageMonthlyLeasingStars.new(end_of_last_month, channel, leasing_stars)
    Job.create(send_image)

    mention = "@channel"
    mention += ' ^'
    send_bluebot_alert(mention, channel)
  end

  leasing_super_stars_by_properties = data[:leasing_super_stars_by_properties]
  leasing_super_stars_by_properties.each do |property_data|
    property = property_data[:property]
    unless property.present? 
      next
    end
    super_stars = property_data[:leasing_data]
    super_stars.each do |super_star|
      channel = property.slack_channel_for_leasing
      name = super_star['agent']
      puts "Bluebot ImageMonthlyLeasingSuperStar graphic, for #{name}, sent to #{channel} channel"
      send_image = Alerts::Commands::SendSlackImageMonthlyLeasingSuperStar.new(end_of_last_month, channel, name)
      Job.create(send_image)
  
      mention = "@channel"
      mention += ' ^'
      send_bluebot_alert(mention, channel)
    end
  end
  
  leasing_goals_missed_by_properties = data[:leasing_goals_missed_by_properties]
  leasing_goals_missed_by_properties.each do |property_data|
    property = property_data[:property]
    unless property.present? 
      next
    end
    missed_goal_agents = property_data[:leasing_data]
    unless missed_goal_agents.count > 0
      next
    end
    missed_goal_agents_message = ""
    missed_goal_agents.each do |missed_goal_agent|
      name = missed_goal_agent['agent']
      sales = missed_goal_agent['sales'].to_s
      goal = missed_goal_agent['goal'].to_s
      past_missed_goals = missed_goal_agent['past_missed_goals']

      missed_goal_agents_message += "*#{name}*: Sales #{sales}, Goal #{goal}\n"

      # Send separate alert message to Property HR channel
      total_missed = 1 + past_missed_goals
      if total_missed == 2
        channel = property.slack_channel_for_hr()
        message = "@channel: *#{name}* has missed their leasing goal for this month, for a total of 2 missed months in the past 12 months.  REMINDER: One more missed month and a write-up will be necessary for this leasing agent.  Please respond in this thread below and tag your TRM and HR with your next steps."
        puts "Redbot alert, for #{name} missing #{total_missed} total goals, sent to #{channel} channel"
        send_hr_warning_message = Alerts::Commands::SendRedBotSlackMessage.new(message, channel)
        Job.create(send_hr_warning_message)  
      elsif total_missed >= 3
        channel = property.slack_channel_for_hr()
        message = "@channel: *#{name}* has missed #{total_missed} months of leasing goals in the last 12 months.  A write-up is needed!  If you disagree this warrants written disciplinary action, please respond in this thread below and tag your TRM and HR."
        puts "Redbot alert, for #{name} missing #{total_missed} total goals, sent to #{channel} channel"
        send_hr_warning_message = Alerts::Commands::SendRedBotSlackMessage.new(message, channel)
        Job.create(send_hr_warning_message)     
      end

    end
    channel = property.slack_channel_for_leasing()
    puts "Redbot image, for missed leasing goals, sent to #{channel} channel"
    send_redbot_image = Alerts::Commands::SendRedBotSlackImage.new(channel, 'Missed Leasing Goal(s)', 'redbot_missed_leasing_goal_image.png', false)
    Job.create(send_redbot_image) 
  
    puts "Redbot alert, for missed leasing goals, sent to #{channel} channel"
    missed_goal_agents_message += "\n@channel ^"
    send_follow_up_message_to_image = Alerts::Commands::SendRedBotSlackMessage.new(missed_goal_agents_message, channel)
    Job.create(send_follow_up_message_to_image) 
  end
end

def send_compliance_stars
  puts "Func send_compliance_stars called"
  blacklist_props = Property.all_blacklist_codes()

  compliance_stars = []
  channel = "#celebrations"
  property_ids_with_no_issues = Set.new

  Property.where.not(code: blacklist_props).order("full_name ASC").each do |property|

    # channel = property.slack_channel_for_leasing
    unless channel.nil?

      star_property_manager = check_for_compliance_star(property)
      unless star_property_manager.nil?
        star_property_manager[:pm_name].present? ? pm_name = star_property_manager[:pm_name] : pm_name = 'PM Name Missing'
        compliance_stars.push( { "property_manager" => pm_name, 
                                 "property" => property.code } )  

        if star_property_manager[:no_issues].present? && star_property_manager[:no_issues] == true
          puts "Found star property_manager, with no issues"
          property_ids_with_no_issues.add(property.id)
        else
          puts "Found star property_manager, with new issues today only"
        end
      end
    end
  end

  if compliance_stars.count > 0
    puts "Sorting ALL compliance_stars"
    compliance_stars.sort! do |a, b|
      a['property'] <=> b['property']
    end
    puts compliance_stars
    puts "Bluebot messages send to #{channel} channel"
    send_image = Alerts::Commands::SendSlackImageComplianceStars.new(Date.today, channel, compliance_stars)
    Job.create(send_image)

    mention = "@channel"
    mention += ' ^'
    send_bluebot_alert(mention, channel)
  end

  # Send out 100% Compliance graphics
  property_ids_with_no_issues.each do |i|
    property = Property.find(i)
    unless property.slack_channel.nil?
      channel = property.update_slack_channel
      message = "#{property.leasing_mention} #{property.talent_resource_manager_mention(nil)} #{property.property_manager_mentions(nil)} ^"
      puts "100% Compliance Message - #{property.code}"

      send_red_bot_slack_alert_image(channel, '100% Compliance', '100_percent_compliance.png', true)
      send_bluebot_alert(message, channel)
    end
  end

end

def check_monthly_maint_inspections
  puts "Func check_monthly_maint_inspections called"

  monthly_maint_sparkle_template_name = 'Maintenance Property Inspection'
  send_bluebot_maint_reminders = false 
  send_redbot_maint_alerts = false 

  # 1 - If 1 week remains, and there's no maint inspection for the month, send a reminder to maint_<prop> channel
  last_week_of_month = Date.today.end_of_month - 7.days
  if Date.today >= last_week_of_month
    send_bluebot_maint_reminders = true
  # 2 - If the 1st of the month, and there was no monthly, maint. inspection completed, send a redbot image to the main_<prop> channel
  elsif Date.today == Date.today.beginning_of_month
    send_redbot_maint_alerts = true
  end

  if send_bluebot_maint_reminders || send_redbot_maint_alerts
    # Pull all active properties
    # Check for an inspection with maintenance template name, completed this month
    blacklist_props = Property.all_blacklist_codes()
    Property.where.not(code: blacklist_props).order("code ASC").each do |property|
      send_reminder = false 
      send_alert = false
      latest_inspection_action = Sparkle::Commands::LatestInspection.new(property: property, template: monthly_maint_sparkle_template_name, created_on: nil)
      data = latest_inspection_action.perform
      if data[:latest_inspection].present?
        if data[:latest_inspection]["completionDate"].present?
          completionDate = Time.at(data[:latest_inspection]["completionDate"]).to_date
          if send_bluebot_maint_reminders && completionDate.present?
            if completionDate < Date.today.beginning_of_month
              # Last inspection was last month, not this month.  Send reminder
              puts "Last inspection was last month, not this month.  Send bluebot_maintenance reminder for #{property.code}"
              send_reminder = true
            else  
              puts "Found inspection for this month.  No reminder needed for #{property.code}"
            end 
          elsif send_redbot_maint_alerts && completionDate.present?
            if completionDate < (Date.today - 1.month).beginning_of_month
              # Last inspection was before previous month, not last month.  Send redobt alert.
              puts "Last inspection was before previous month, not last month.  Send redobt alert for #{property.code}"
              send_alert = true
            else  
              puts "Found inspection for previous month.  No alert needed for #{property.code}"
            end
          elsif (send_bluebot_maint_reminders || send_redbot_maint_alerts) && completionDate.nil?
            puts "ERROR: completionDate not found"
          else  
            puts "ERROR: Unknown case found for last inspection"
          end
        end
      elsif data[:property_data].present?
        if send_bluebot_maint_reminders
          puts "No inspection found.  Send bluebot_maintenance reminder for #{property.code}"
          send_reminder = true
        elsif send_redbot_maint_alerts
          puts "No inspection found.  Send redobt alert for #{property.code}"
          send_alert = true
        else  
          puts "ERROR: Unknown case for no inspection"
        end
      end

      if send_reminder 
        channel = property.slack_channel_for_maint
        message = property.bluebot_maint_mention(false, false)
        pm_user_mentions = property.property_manager_mentions(nil)
        message += " #{pm_user_mentions}"
        message += " - REMINDER: Monthly Maintenance Inspection is due by end of month.\n"
        message += "```Open Sparkle and complete a *#{monthly_maint_sparkle_template_name}* inspection.```"
        send_alert = Alerts::Commands::SendMaintBlueBotSlackMessage.new(message, channel)
        Job.create(send_alert)
      elsif send_alert
        channel = property.slack_channel_for_maint
        title = "Missed Monthly Maintenance Inspection"
        send_red_bot_slack_alert_image(channel, title, 'redbot_monthly_maint_inspection_missed.png', false)
        message = property.bluebot_maint_mention(false, false)
        pm_user_mentions = property.property_manager_mentions(nil)
        message += " #{pm_user_mentions}"
        message += " ^"
        send_red_bot_slack_alert(message, channel)
      end

    end
  end

end

def check_for_compliance_star(property)
  puts "Func check_for_compliance_star called for #{property.code}"

  # Check to see if there are metrics on 1st day of last month first
  # metrics = Metric.where(date: beginning_of_last_month).where(property: property).first
  # if metrics.nil?
  #   puts "No metrics found for #{property.code} on the 1st of last month"
  #   return nil
  # end

  # Check to see if property has any strikes
  # if property.manager_strikes > 0
  #   return nil
  # end

  no_issues_streak = 0
  streak = 0
  longest_streak = 0
  longest_no_issues_streak = 0
  # tuesdays = every_tuesday_of_last_month
  tuesdays = last_or_current_tuesday
  tuesdays.each do |d|
    issues_found = ComplianceIssue.where(date: d, property: property, trm_notify_only: false)
    prev_day_issues_found = ComplianceIssue.where(date: d - 1.day, property: property, trm_notify_only: false)
    puts "Found #{issues_found.count} issues"
    # issues.append(issues_found)
    if issues_found.count == 0
      no_issues_streak += 1
      streak += 1
    else
      issue_culprit_names = []
      issues_found.each do |ci|
        culprits = ci.culprits.split(';')
        culprits.each do |culprit|
          issue_culprit_names.append(ci.issue + culprit)
        end
      end
      prev_day_issue_culprit_names = []
      prev_day_issues_found.each do |ci|
        culprits = ci.culprits.split(';')
        culprits.each do |culprit|
          prev_day_issue_culprit_names.append(ci.issue + culprit)
        end
      end
      # Find matching only
      intersection = issue_culprit_names & prev_day_issue_culprit_names
      # If none match, only new issues, which is allowed for stars
      if intersection.count == 0
        streak += 1
      else
        streak = 0
      end
    end
    if streak > longest_streak
      longest_streak = streak
    end
    if no_issues_streak > longest_no_issues_streak
      longest_no_issues_streak = no_issues_streak
    end
  end

  puts "Longest streak of #{longest_streak} Tuesdays with no issues vs #{tuesdays.count} total Tuesdays"

  property_manager = property.property_manager_user()
  if !property_manager.nil?
    pm_name = "#{property_manager.first_name} #{property_manager.last_name}"
  else
    pm_name = "#{property.code} PM (unset)"
  end

  # just looking for zero issues, today or most recent Tuesday, if Tuesday is not today
  if longest_streak == tuesdays.count
    no_issues = longest_no_issues_streak == tuesdays.count
    return { pm_name: pm_name, no_issues: no_issues }
  end  

  return nil
end

def check_property_inspection_alerts_and_creation_dates
  blacklist_props = Property.all_blacklist_codes()

  Property.where.not(code: blacklist_props).order("full_name ASC").each do |property|
    property.update_latest_inspection(nil)
    unless property.latest_inspection.nil? && property.latest_inspection_property.nil?

      # Check for Compliance Alert(s)
      complianceAlert = property.latest_inspection_alerts[:complianceAlert]
      if complianceAlert.present?
        puts "Compliance Issue, Inspection Alert (#{property.code}): #{complianceAlert}"
        add_compliance_issue(property, complianceAlert, 'Blueshift Product Inspection Alert')
        # send_redbot_alert(alert, '#manager-deadlines')
      end
    end
  end

  # Data Import Record
  new_record = DataImportRecord.apiJSON(
    source: DataImportRecordSource::SPARKLE, 
    data_date: nil, 
    data_datetime: nil, 
    title: DataImportRecordSparkleJSONTitle::LatestInspectionComplianceChecksForProperties)
  new_record.data_imported = true
  new_record.save!
  new_record.sendNoficationToSlack()
end

def check_for_missing_data_today  
  missing_data = []
  # Metric
  data = Metric.where(date: Date.today).where(main_metrics_received: true).first
  if data.nil?
    missing_data.append('Cobalt Daily Report - Property Metrics')
  end

  # Metric (Portfolio and Team Sales Addendum)
  portfolio_property = Property.portfolio
  data = Metric.where(date: Date.today, property: portfolio_property).first
  if data.nil? || data.addendum_received != true
    missing_data.append('Cobalt Portfolio Sales Addendum')
  end

  # RentChangeReason
  data = RentChangeReason.where(date: Date.today).first
  # data = Metric.includes(:rent_change_reasons).where(metrics: {date: Date.today}).where.not(rent_change_reasons: {id: nil}).first
  if data.nil?
    missing_data.append('Rent Change Suggestion Report')
  end

  # ComplianceIssue
  last_import_by_date = DataImportRecord.lastImportByDataDate(source: DataImportRecordSource::YARDI, title: DataImportRecordYardiSpreadSheetTitle::RedBotComplianceReport)
  # Ensure last import has data, and data came in today
  unless last_import_by_date.present? && last_import_by_date.data_date.present? && last_import_by_date.data_date == Date.today
    last_import = DataImportRecord.lastImport(source: DataImportRecordSource::YARDI, title: DataImportRecordYardiSpreadSheetTitle::RedBotComplianceReport)
    # Ensure last import is less than 24 hrs ago
    unless last_import.present? && last_import.generated_at.present? && last_import.generated_at > DateTime.now - 1.day
      # Otherwse, last import > 24h ago, report import is missing
      missing_data.append('Red Bot Compliance Report - Compliance Issues')
    end
  end

  # ConversionsForAgent
  data = ConversionsForAgent.where(date: Date.today).first
  if data.nil?
    missing_data.append('Leads Problem Report - Conversions for Agents/Properties')
  end

  # SalesForAgent
  data = SalesForAgent.where(date: Date.today).first
  if data.nil?
    missing_data.append('Cobalt Agent Sales Report')
  end

  # TurnsForProperty
  data = TurnsForProperty.where(date: Date.today).first
  if data.nil?
    missing_data.append('Redbot Maintenance Report - Turns/WOs')
  end

  # AccountsPayableComplianceIssue
  # Ensure last import has data, and data came in today
  last_import_by_date = DataImportRecord.lastImportByDataDate(source: DataImportRecordSource::YARDI, title: DataImportRecordYardiSpreadSheetTitle::APRedBotComplianceReport)
  unless last_import_by_date.present? && last_import_by_date.data_date.present? && last_import_by_date.data_date == Date.today
    last_import = DataImportRecord.lastImport(source: DataImportRecordSource::YARDI, title: DataImportRecordYardiSpreadSheetTitle::APRedBotComplianceReport)
    # Ensure last import is less than 24 hrs ago
    unless last_import.present? && last_import.generated_at.present? && last_import.generated_at > DateTime.now - 1.day
      # Otherwse, last import > 24h ago, report import is missing
      missing_data.append('AP Redbot Compliance Report')
    end
  end

  # IncompleteWorkOrder
  data = IncompleteWorkOrder.where("updated_at >= ?", Time.now - (3600 * 24)).first
  if data.nil?
    missing_data.append('Bluestone Work Order Incomplete List')
  end

  # RenewalsUnknownDetail
  # Ensure last import has data, and data came in today
  last_import_by_date = DataImportRecord.lastImportByDataDate(source: DataImportRecordSource::YARDI, title: DataImportRecordYardiSpreadSheetTitle::CobaltUnknownDetailReport)
  unless last_import_by_date.present? && last_import_by_date.data_date.present? && last_import_by_date.data_date == Date.today
    last_import = DataImportRecord.lastImport(source: DataImportRecordSource::YARDI, title: DataImportRecordYardiSpreadSheetTitle::CobaltUnknownDetailReport)
    # Ensure last import is less than 24 hrs ago
    unless last_import.present? && last_import.generated_at.present? && last_import.generated_at > DateTime.now - 1.day
      # Otherwse, last import > 24h ago, report import is missing
      missing_data.append('Cobalt Unknown Detail Report')
    end
  end

  # CollectionsNonEvictionPast20Detail
  # Ensure last import has data, and data came in today
  last_import_by_date = DataImportRecord.lastImportByDataDate(source: DataImportRecordSource::YARDI, title: DataImportRecordYardiSpreadSheetTitle::CobaltCollectionDetailReport)
  unless last_import_by_date.present? && last_import_by_date.data_date.present? && last_import_by_date.data_date == Date.today
    last_import = DataImportRecord.lastImport(source: DataImportRecordSource::YARDI, title: DataImportRecordYardiSpreadSheetTitle::CobaltCollectionDetailReport)
    # Ensure last import is less than 24 hrs ago
    unless last_import.present? && last_import.generated_at.present? && last_import.generated_at > DateTime.now - 1.day
      # Otherwse, last import > 24h ago, report import is missing
      missing_data.append('Cobalt Collection Detail Report - Non-Eviction with Balance over 20 days > $500')
    end
  end

  # AverageRentsBedroomDetail
  data = AverageRentsBedroomDetail.where(date: Date.today).first
  if data.nil?
    missing_data.append('Cobalt Rent Detail Report - Net Avg. Rent & Market Rent per # of Beds')
  end

  # CompSurveyByBedDetail
  data = CompSurveyByBedDetail.where(date: Date.today).first
  if data.nil?
    missing_data.append('Comp Survey By Bed Summary')
  end

  # CollectionsDetail
  data = CollectionsDetail.where("date_time >= ?", Time.now - (3600 * 24)).first
  if data.nil?
    missing_data.append('Collections Snapshot')
  end

  # CollectionsByTenantDetail
  data = CollectionsByTenantDetail.where("date_time >= ?", Time.now - (3600 * 24)).first
  if data.nil?
    missing_data.append('Collections Snapshot by Tenant')
  end

  # Check to makes sure all active properties have Manager Template names set
  blacklist_props = Property.all_blacklist_codes()

  Property.where.not(code: blacklist_props).order("code ASC").each do |property|
    if property.sparkle_blshift_pm_templ_name.nil?
      temp_message = "@channel: Cobalt data missing there is:\n"
      temp_message += "`Sparkle Blueshift Manager Template Name for #{property.code}`"
      send_corp_yodabot_alert(temp_message, '#onboarding-property')
    end
  end

  if missing_data.count > 0
    message = "@channel: Cobalt data missing there is:\n"
    missing_data.each do |d|
      message += "\n`#{d}`"
    end
    puts "YODABOT: #{message}"
    send_corp_yodabot_alert(message, '#coding')
  end
  # else
  #   message = "All Cobalt data there is. :white_check_mark:"
  #   send_corp_yodabot_alert(message, '#coding')
  # end
end

def backfill_blueshift_archived_failure_reasons
  # Set Druid Leads to Conversion for Property
  archived_blueshifts = BlueShift.where(archived: true)
  archived_blueshifts.each do |blueshift|
    # date = blueshift.initial_archived_date
    # if date.nil?
    # end
    date = blueshift.latest_fix_by_date() + 1.day
    if blueshift.archived_status == "failure"
      blueshift.archived_failure_reasons = blueshift.auto_archive_failure_reasons_for_date(date)
      blueshift.save(validate: false)
    else
      blueshift.archived_failure_reasons = ''
      blueshift.save(validate: false)
    end
  end
end

def reprocess_druid_stats
  # Set Druid Leads to Conversion for Property
  property_codes = Property.properties.where(active: true).pluck('code')
  property_codes.each do |property_code|
    stats_date = Date.today - 1.day
    druid_property_prospect_stats = StatRecord.druidPropertyProspectStats(stats_date, property_code)
    while druid_property_prospect_stats != nil
      if !druid_property_prospect_stats.nil?
        druidProspectStatsForProperty = druid_property_prospect_stats.druidProspectStatsForProperty(property_code)
        if !druidProspectStatsForProperty.nil?
          value = druidProspectStatsForProperty['Prospects30']
          cfp = ConversionsForAgent.where(date: stats_date, agent: property_code).first
          if !cfp.nil?
            cfp.druid_prospects_30days = BigDecimal(value, 2)
            cfp.save!
            puts "Set druid_prospects_30days for #{property_code}, on #{stats_date}, with value = #{cfp.druid_prospects_30days}"
          end
        end
      end
      stats_date = stats_date - 1.day
      druid_property_prospect_stats = StatRecord.druidPropertyProspectStats(stats_date, property_code)
    end
  end
end

def reimport_druid_stats
  earliest_import_date = Date.parse("2019-01-01")
  conversions_for_properties = ConversionsForAgent.where(is_property_data: true).where("date >= ?", earliest_import_date).order("date ASC")
  druid_prospect_stats_url = Settings.druid_prospect_stats_url
  if druid_prospect_stats_url.nil? || druid_prospect_stats_url == ''
    return
  end

  data_importer_called = false

  conversions_for_properties.each do |cfp|
    url = druid_prospect_stats_url + "&stats=properties&ids[]=#{cfp.property.code}&date=#{cfp.date}"
    command = StatsImporter.new(source: 'druid', name: "#{cfp.property.code}_prospect_stats", url: url)
    Job.create(command)
    data_importer_called = true
    puts "StatsImporter job created with URL: #{url}"
  end

  # Data Import Record
  new_record = DataImportRecord.apiJSON(
    source: DataImportRecordSource::BLUESKY, 
    data_date: nil, 
    data_datetime: nil, 
    title: DataImportRecordBlueskyJSONTitle::ProspectStatsForAllProperties)
  new_record.data_imported = data_importer_called
  new_record.save!
  new_record.sendNoficationToSlack()
end

def backfill_process_leads_needed_for_properties
  # Set Druid Leads to Conversion for Property
  property_codes = Property.properties.where(active: true).pluck('code')
  property_codes.each do |property_code|
    date = Date.today
    cfp = ConversionsForAgent.where(date: date, agent: property_code).first
    consecutive_nils = 0
    while consecutive_nils < 3
      if !cfp.nil?
        metrics = cfp.property_metrics()
        cfp.num_of_leads_needed = metrics[:num_of_leads_needed]
        cfp.save!
        puts "Set num_of_leads_needed for #{property_code}, on #{date}."
        consecutive_nils = 0
      else
        consecutive_nils += 1
      end
      date = date - 1.day
      cfp = ConversionsForAgent.where(date: date, agent: property_code).first
    end
  end
end

def test_sending_turns_for_properties
  import_date = (Time.now - 10.day).to_date

  # Send images to slack
  turns_for_properties = TurnsForProperty.where(date: import_date).order("property_id ASC")
  if !turns_for_properties.nil? && turns_for_properties.count > 0
    # Daily
    for tfp in turns_for_properties do
      send_slack_image_maint_work_orders(tfp)            
    end

    day_of_the_week = import_date.strftime("%A")

    # Only on Tuesdays
    for tfp in turns_for_properties do
      send_slack_image_maint_turns_goal(tfp)            
    end
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


def test_sending_leasing_goals
  import_date = (Time.now - 10.day).to_date

  # Send images to slack
  sales_for_agents = SalesForAgent.where(date: (Time.now - 10.days).to_date).order("property_id ASC, agent ASC")
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


def test_sending_leasing_goal_slack_messages
  properties = Property.properties.where(active: true)
  properties.each do |prop|
    latest_metric = Metric.where(property: prop).where(main_metrics_received: true).order("date DESC").first
    send_leasing_goal_slack_message(prop, latest_metric, Time.now.to_date)
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

# def check_property_inspection_creation_dates
#   blacklist_props = MetricChartData.property_blacklist()
  
#   Property.where.not(code: blacklist_props).order("full_name ASC").each do |property|
#     unless property.code == 'Portfolio'
#       inspection = latest_product_inspection(property)
#       unless inspection.nil?
#         inspection_overdue = overdue_for_property_inspection?(property, inspection)
#         if inspection_overdue 
#           add_compliance_issue(property, 'Latest Product Inspection Over 2 Weeks Old', 'Blueshift Product Inspection')
#         end
#       end
#     end
#   end
# end

# def latest_product_inspection(property)
#   latest_inspection_action = Sparkle::Commands::LatestInspection.new(property: property, created_on: nil)
#   data = latest_inspection_action.perform 
#   if data[:error].present?
#     puts "ERROR: scheduler - latest_product_inspection - #{data[:error]}"
#   end
#   return data[:latest_inspection]
# end

# def message_alert_for_property_inspection(property, inspection)
#   alert_users = '@kristen_360'    
#   property_manager = property.property_manager_user
#   unless property_manager.nil? || property_manager.slack_username.nil? || property_manager.slack_username == ""
#     alert_users = "@#{property_manager.slack_username} @kristen_360"
#   end

#   unless inspection.nil? || !inspection['creationDate'].present?
#     alert = inspection['alert']
#     if !alert.nil? 
#       return "*#{property.full_name}* has an inspection alert ( #{alert_users} ): `#{alert}`"
#     end
#   else 
#     if inspection.present?
#       alert = inspection   
#       return "*#{property.full_name}* has an inspection alert ( #{alert_users} ): `#{alert}`"  
#     end      
#   end

#   return nil
# end

# def alert_for_property_inspection(inspection)
#   unless inspection.nil? || inspection['creationDate'].nil? || inspection['meta'].nil?
#     alert = inspection['meta']['complianceAlert']
#     if alert.present? 
#       return alert
#     end
#   end

#   return nil
# end

# def overdue_for_property_inspection?(property, inspection)
#   unless inspection.nil? || !inspection['creationDate'].present?
#     creation_date_string = inspection['creationDate']
#     if !creation_date_string.nil? 
#       creation_date = Date.strptime(creation_date_string, '%m/%d/%y')
#       expiration_date = Date.today - 15.day
#       return creation_date <= expiration_date
#     end
#   end

#   return false
# end

# def send_redbot_alert(alert, channel)
#   send_alert = Alerts::Commands::SendRedBotSlackMessage.new(alert, channel)
#   Job.create(send_alert)
# end  

def check_for_calendar_events
  today = Date.today
  events = CalendarBotEvent.where(sent: false, event_date: today)
  events.each do |event|
    send_calendarbot_image(slack_channel: "#diversity-inclusion", title: event.title, description: event.description, background_color: event.background_color, border_color: event.border_color, text_color: event.text_color)
    event.sent = true
    event.save
  end
end

def send_calendarbot_image(slack_channel:, title:, description:, background_color:, border_color:, text_color:)
  send_image = Alerts::Commands::SendCalendarBotSlackImage.new(slack_channel, title, description, background_color, border_color, text_color)
  Job.create(send_image)
end 

def send_bluebot_alert(message, channel)
  send_alert = Alerts::Commands::SendSlackMessage.new(message, channel)
  Job.create(send_alert)
end 

def send_corp_yodabot_alert(message, channel)
  send_alert = Alerts::Commands::SendCorpYodaBotSlackMessage.new(message, channel)
  Job.create(send_alert)
end

def send_red_bot_slack_alert_image(channel, title, image_filename, send_as_blue_bot)
  send_alert = Alerts::Commands::SendRedBotSlackImage.new(channel, title, image_filename, send_as_blue_bot)
  Job.create(send_alert)  
end

def send_red_bot_slack_alert(message, channel)
  send_alert = Alerts::Commands::SendRedBotSlackMessage.new(message, channel)
  Job.create(send_alert)   
end

def add_compliance_issue(property, issue, culprits)
  compliance_issue = get_new_or_existing_compliance_issue(Date.today, property, issue)
  compliance_issue.num_of_culprits = 1
  compliance_issue.culprits = culprits
  compliance_issue.save!
end

def get_new_or_existing_compliance_issue(date, property, issue)
  return ComplianceIssue.where(date: date, property: property, issue: issue, trm_notify_only: false).first_or_initialize
end

def every_tuesday_of_last_month
  dates = []
  date = beginning_of_last_month
  while date < Date.today.beginning_of_month
    if date.wday == 2
      dates.append(date)
    end
    date += 1.day
  end
  return dates
end

def last_two_tuesdays
  dates = []
  # Not including today
  date = Date.today - 1.day
  while dates.count < 2
    if date.wday == 2
      dates.append(date)
    end
    date -= 1.day
  end
  return dates
end

def last_or_current_tuesday
  dates = []
  # Not including today
  date = Date.today
  while dates.count < 1
    if date.wday == 2
      dates.append(date)
    end
    date -= 1.day
  end
  return dates
end

def beginning_of_last_month
  Date.today.last_month.beginning_of_month
end

def number(value)
  number_with_precision(value, precision: 0, strip_insignificant_zeros: true)  
end


# def check_for_new_or_updated_comments
#   # Grab all comments for today, ordered by updated_at date, ASC
  

#   # for each comment, check to see if updated_at is different that updated_at_notification_sent (could be null)
#     # check to see if created_at is different than updated_at.  If so, then this is an update?
#     # for each comment, lookup thread, then lookup corresponding blue_shift or maint_blue_shift
#       # for the blue_shift/maint_blue_shift, look up which thread it is
#       # look up user who created/updated comment, and send slack message out, using their name?/slack_username?, which property and thread, and the body of comment
# end
