require 'clockwork'
require_relative './config/boot'
require_relative './config/environment'
require_relative './lib/stats_importer'
require 'bigdecimal'

include Clockwork

# every(1.day, 'Queueing UpdateBlueShiftStatus job', at: ['3:00'], tz: 'America/Chicago') do
#   command = Properties::Commands::UpdateBlueShiftStatus.new
#   Job.create(command)
# end

# every(1.day, 'Queueing UpdateMaintBlueShiftStatus job', at: ['3:01'], tz: 'America/Chicago') do
#   command = Properties::Commands::UpdateMaintBlueShiftStatus.new
#   Job.create(command)
# end

every(4.hours, "Updating Ultipro Data & Linking to Workable Jobs") do
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
      employee = Employee.where(workable_name: hired_candidate_full_name).where("date_in_job > ?", job.hired_at - 1.month).where("date_in_job < ?", job.hired_at + 1.month).first                         
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

every(45.minutes, "Updating Property Units via Yardi Voyager Data") do
  service = Yardi::Voyager::Api::Units.new
  properties = Property.properties.where(active: true).where.not(code: Property.portfolio_code())
  properties.each do |prop|
    next if prop.code.downcase.include? "Office"
    begin
      units_data = service.getUnits(prop.code)
    rescue => e
      Airbrake.notify(e, error_message: "Updating Property Units failed for #{prop.code}")
    end

    next if units_data.nil?
    units_data.each do |unit_data|
      PropertyUnit.import_yardi_unit_data(prop, unit_data)
    end
    puts "Property Units updated for #{prop.code}"
  end
end


every(1.hour, 'Importing All Workable Jobs, and Updating Job Activites') do
  # NOTE: requires ENV variable WORKABLE_API_AUTH_TOKEN
  # To update ALL job activites, there is rack task available for that.

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
    Job.create(update_workable_job_activities)
  end


  # Update Closed jobs, but only back 60 days from last member activity
  # Just in case they got re-opened, updated, and re-closed/re-archived, for any reason
  # I thought 60 days back would be back far enough.
  # OR... Update all closed, with no activity jobs (if any).  These would be newly added jobs, already closed.
  date_time = DateTime.now - 60.days
  open_states = ["published", "closed"]
  workable_jobs = WorkableJob.where.not(state: open_states).where("last_activity_member_datetime > ? OR last_activity_member_datetime = ?", date_time, nil).order("job_created_at DESC")
  if workable_jobs.count > 0
    jobs_exist = true
    puts "Cobalt Recruiting: Updating Activities for #{workable_jobs.count} NOT OPEN (NOT published & NOT closed), LAST MEMBER ACTIVITY > 60 Days Ago Jobs OR Not Set Yet."
  end 
  workable_jobs.each do |job|
    update_workable_job_activities = Workable::Commands::JobActivities.new(workable_job: job)
    Job.create(update_workable_job_activities)
  end

  # Data Import Record
  new_record = DataImportRecord.apiJSON(
    source: DataImportRecordSource::WORKABLE, 
    data_date: nil, 
    data_datetime: nil, 
    title: DataImportRecordWorkableJSONTitle::JobActivities)
  new_record.data_imported = jobs_exist
  new_record.save!
  new_record.sendNoficationToSlack()
end

every(30.minutes, 'Queueing Druid Prospect Stats - StatsImporter job') do
  data_importer_called = false
  # Loop through all properties, to pull druid prospect stats
  property_codes = Property.properties.where(active: true).pluck('code')
  property_codes.each do |property_code|
    druid_prospect_stats_url = Settings.druid_prospect_stats_url
    if !druid_prospect_stats_url.nil? && druid_prospect_stats_url != ''
      druid_prospect_stats_url += "&stats=properties&ids[]=#{property_code}"
      command = StatsImporter.new(source: 'druid', name: "#{property_code}_prospect_stats", url: druid_prospect_stats_url)
      Job.create(command)
      data_importer_called = true

      # Set Druid Leads to Conversion for Property
      druid_property_prospect_stats = StatRecord.druidPropertyProspectStats(Date.today, property_code)
      if !druid_property_prospect_stats.nil?
        druidProspectStatsForProperty = druid_property_prospect_stats.druidProspectStatsForProperty(property_code)
        if !druidProspectStatsForProperty.nil?
          value = druidProspectStatsForProperty['Prospects30']
          cfp = ConversionsForAgent.where(date: Date.today, agent: property_code).first
          if !cfp.nil?
            cfp.druid_prospects_30days = BigDecimal(value, 2)
            cfp.save!
          else
            cfp = ConversionsForAgent.where(date: Date.today - 1.day, agent: property_code).first
            if !cfp.nil?
              cfp.druid_prospects_30days = BigDecimal(value, 2)
              cfp.save!
            end
          end
        end
      end
    end
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

  # Clean up old records
  # StatRecord.connection.execute("DELETE FROM stat_records WHERE id NOT IN (SELECT id FROM (SELECT DISTINCT (generated_at) generated_at, source, name FROM stat_records WHERE success = true ORDER BY generated_at DESC) AS tmp)")
end

every(20.minutes, 'Queueing blueshift, auto-archiving/requirement checker job') do
  first_active_property = Property.properties.where(active: true).first
  if !first_active_property.nil?
    todays_metric = Metric.where(property: first_active_property, date: Date.today).where(main_metrics_received: true).first
    if todays_metric.nil?
      latest_metric = Metric.where(property: first_active_property).where(main_metrics_received: true).order("date DESC").first
      if !latest_metric.nil?
        Property.properties.where(active: true).each do |p|
          Property.update_property_blue_shift_status(p, latest_metric.date, false)
          Property.update_property_maint_blue_shift_status(p, latest_metric.date, false)
          Property.update_property_trm_blue_shift_status(p, latest_metric.date, false)
        end
      end
    else
      Property.properties.where(active: true).each do |p|
        Property.update_property_blue_shift_status(p, todays_metric.date, false)
        Property.update_property_maint_blue_shift_status(p, todays_metric.date, false)
        Property.update_property_trm_blue_shift_status(p, todays_metric.date, false)
      end
    end
  end
end

module Clockwork
  error_handler do |error|
    Airbrake.notify(error)
  end
end
