require 'dotiw'

class WorkableJobsController < ApplicationController
  before_action :set_workable_job, only: [:show, :edit, :update]

  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper

  # GET /workable_jobs/1
  # GET /workable_jobs/1.json
  def show
  end

  # GET /workable_jobs/1/edit
  def edit
  end

  def update 
    puts workable_job_params    
    respond_to do |format|
      if @workable_job.update(workable_job_params)
        notice_text = 'Workable Job was successfully updated.'
        format.html { redirect_to @workable_job, notice: notice_text }
        format.json { render :view, status: :ok, location: @workable_job }
      else
        format.html { render :edit }
        format.json { render json: @workable_job.errors, status: :unprocessable_entity }
      end
    end

  end


  def index
    authorize! :show_workable_jobs, WorkableJob.new()

    @sort_options = ['Days Open', 'Job Title', 'Region/Property']
    if params[:sort_by].present?
      case params[:sort_by]
      when @sort_options[0]
        @sort_option_selected = @sort_options[0]
      when @sort_options[1]
        @sort_option_selected = @sort_options[1]
      when @sort_options[2]
        @sort_option_selected = @sort_options[2]
      else
        @sort_option_selected = @sort_options[0]
      end
    else
      @sort_option_selected = @sort_options[0]
    end

    puts @sort_option_selected

    # Counts
    @alerts_counter_enabled = true
    @alerts_lvl2_count = 0
    @alerts_lvl1_count = 0

    # Open 360/Property Jobs
    open_states = ["published", "closed"]
    open_jobs = WorkableJob.where(state: open_states)
    open_360_jobs = open_jobs.select { |j| j.property.type == 'Team' || j.property.code == Property.portfolio_code }
    open_property_jobs = open_jobs.select { |j| j.property.type != 'Team' && j.property.code != Property.portfolio_code }
    @open_360_jobs_data = sort_jobs_data(jobs_data(jobs: open_360_jobs, property_level: false, closed_jobs: false, show_employee_name: false))
    @open_property_jobs_data_by_team = separate_jobs_data_by_team(jobs_data(jobs: open_property_jobs, property_level: true, closed_jobs: false, show_employee_name: false))
    @open_360_jobs_count = open_360_jobs.select { |j| !j.is_duplicate }.count
    @open_property_jobs_count = open_property_jobs.select { |j| !j.is_duplicate }.count

    closed_states = ["archived"]
    # ALL 360/Property closed jobs
    all_closed_jobs = WorkableJob.where(state: closed_states).where(is_hired: true).order("job_created_at ASC")
    all_closed_360_jobs = all_closed_jobs.select { |j| j.property.type == 'Team' || j.property.code == Property.portfolio_code }
    all_closed_property_jobs = all_closed_jobs.select { |j| j.property.type != 'Team' && j.property.code != Property.portfolio_code }
    @all_closed_all_stats = stats_data(jobs: all_closed_jobs, alerts_enabled: true)
    @all_closed_360_stats = stats_data(jobs: all_closed_360_jobs, alerts_enabled: true)
    # Separate properties by their team
    all_closed_property_jobs_by_team = separate_jobs_by_team(all_closed_property_jobs)
    @all_closed_property_by_team_stats = []
    # Calc stats per team
    all_closed_property_jobs_by_team.each do |jobs_for_team|
      @all_closed_property_by_team_stats << stats_data(jobs: jobs_for_team, alerts_enabled: true)
    end

    # YTD 360/Property closed jobs
    date_time_ytd = DateTime.now - 365.days
    ytd_closed_jobs = WorkableJob.where(state: closed_states).where(is_hired: true).where("job_created_at > ?", date_time_ytd)
    ytd_closed_360_jobs = ytd_closed_jobs.select { |j| j.property.type == 'Team' || j.property.code == Property.portfolio_code }
    ytd_closed_property_jobs = ytd_closed_jobs.select { |j| j.property.type != 'Team' && j.property.code != Property.portfolio_code }
    @closed_360_jobs_data = sort_jobs_data(jobs_data(jobs: ytd_closed_360_jobs, property_level: false, closed_jobs: true, show_employee_name: true))
    @closed_property_jobs_data_by_team = separate_jobs_data_by_team(jobs_data(jobs: ytd_closed_property_jobs, property_level: true, closed_jobs: true, show_employee_name: true))
    @ytd_closed_all_stats = stats_data(jobs: ytd_closed_jobs, alerts_enabled: true)
    @ytd_closed_360_stats = stats_data(jobs: ytd_closed_360_jobs, alerts_enabled: true)
    # Separate properties by their team
    ytd_closed_property_jobs_by_team = separate_jobs_by_team(ytd_closed_property_jobs)
    @ytd_closed_property_by_team_stats = []
    # Calc stats per team
    ytd_closed_property_jobs_by_team.each do |jobs_for_team|
      @ytd_closed_property_by_team_stats << stats_data(jobs: jobs_for_team, alerts_enabled: true)
    end

    # 6mo 360/Property closed jobs
    date_time_six_mo = DateTime.now - 6.months
    six_mo_closed_jobs = WorkableJob.where(state: closed_states).where(is_hired: true).where("job_created_at > ?", date_time_six_mo)
    six_mo_closed_360_jobs = six_mo_closed_jobs.select { |j| j.property.type == 'Team' || j.property.code == Property.portfolio_code }
    six_mo_closed_property_jobs = six_mo_closed_jobs.select { |j| j.property.type != 'Team' && j.property.code != Property.portfolio_code }
    @six_mo_closed_all_stats = stats_data(jobs: six_mo_closed_jobs, alerts_enabled: true)
    @six_mo_closed_360_stats = stats_data(jobs: six_mo_closed_360_jobs, alerts_enabled: true)
    # Separate properties by their team
    six_mo_closed_property_jobs_by_team = separate_jobs_by_team(six_mo_closed_property_jobs)
    @six_mo_closed_property_by_team_stats = []
    # Calc stats per team
    six_mo_closed_property_jobs_by_team.each do |jobs_for_team|
      @six_mo_closed_property_by_team_stats << stats_data(jobs: jobs_for_team, alerts_enabled: true)
    end

    # 3mo 360/Property closed jobs
    date_time_three_mo = DateTime.now - 3.months
    three_mo_closed_jobs = WorkableJob.where(state: closed_states).where(is_hired: true).where("job_created_at > ?", date_time_three_mo)
    three_mo_closed_360_jobs = three_mo_closed_jobs.select { |j| j.property.type == 'Team' || j.property.code == Property.portfolio_code }
    three_mo_closed_property_jobs = three_mo_closed_jobs.select { |j| j.property.type != 'Team' && j.property.code != Property.portfolio_code }
    @three_mo_closed_all_stats = stats_data(jobs: three_mo_closed_jobs, alerts_enabled: false)
    @three_mo_closed_360_stats = stats_data(jobs: three_mo_closed_360_jobs, alerts_enabled: false)
    # Separate properties by their team
    three_mo_closed_property_jobs_by_team = separate_jobs_by_team(three_mo_closed_property_jobs)
    @three_mo_closed_property_by_team_stats = []
    # Calc stats per team
    three_mo_closed_property_jobs_by_team.each do |jobs_for_team|
      @three_mo_closed_property_by_team_stats << stats_data(jobs: jobs_for_team, alerts_enabled: true)
    end

  end

  def jobs_data(jobs:, property_level:, closed_jobs:, show_employee_name:)
    if closed_jobs == true
      @alerts_counter_enabled = false
    else
      @alerts_counter_enabled = true
    end
    jobs.collect do |j| 
      job_created_at = j.job_created_at
      if j.original_job_created_at.present?
        job_created_at = j.original_job_created_at
      end
      date_opened = job_created_at.to_date.strftime("%m/%d/%y")
      if closed_jobs == true
        if j.hired_at.present?
          days_open = (j.hired_at.to_datetime - job_created_at.to_datetime).to_i
        else
          days_open = "?"
        end
      else
        days_open = (DateTime.now - job_created_at.to_datetime).to_i
      end
      if j.last_activity_member_datetime.present?
        last_activity_member_date = timeAgo(datetime: j.last_activity_member_datetime.to_datetime)
        # last_activity_member_date = j.last_activity_member_datetime.to_date.strftime("%m/%d/%Y")
      end
      if j.last_activity_candidate_datetime.present?
        last_activity_candidate_date = timeAgo(datetime: j.last_activity_candidate_datetime.to_datetime)
        # last_activity_candidate_date = j.last_activity_candidate_datetime.to_date.strftime("%m/%d/%Y")
      end

      title = j.title
      title_bkg_color = 'transparent'
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

      allow_edit = false
      if show_employee_name == true && j.employee_id != nil
        allow_edit = true
        employee = Employee.find(j.employee_id)
        if employee.present?
          title = "#{employee.first_name.upcase} #{employee.last_name.upcase} - #{title}"
        end
      elsif show_employee_name == true && j.hired_candidate_name != nil
        allow_edit = true
        title = "#{j.hired_candidate_name.upcase} - #{title}"
        unless j.employee_ignore
          title_bkg_color = 'red'
        end
      end

      # Notes / Alerts
      notes_alerts = []
      if j.last_offer_sent_at.present?
        if closed_jobs == true
          notes_alerts << note("#{j.last_offer_sent_at.to_date.strftime("%m/%d/%y")}: Offer Sent")
        else
          notes_alerts << note("#{timeAgo(datetime: j.last_offer_sent_at.to_datetime)}: Offer Sent")
        end
        if j.offer_accepted_at.present?
          time_to_fill = (j.offer_accepted_at.to_datetime - job_created_at.to_datetime).to_i
          if closed_jobs == true
            notes_alerts << note("#{j.offer_accepted_at.to_date.strftime("%m/%d/%y")}: Offer Accepted")
          else
            notes_alerts << note("#{timeAgo(datetime: j.offer_accepted_at.to_datetime)}: Offer Accepted")
          end
        else
          extended = !property_level || j.title == 'Property Manager'
          alert = alertForNoOfferAccepted(datetime: job_created_at.to_datetime, extended: extended)
          if alert.present?
            notes_alerts << alert
          end
        end
      else 
        extended = !property_level || j.title == 'Property Manager'
        alert = alertForNoOfferSent(datetime: job_created_at.to_datetime, extended: extended)
        if alert.present?
          notes_alerts << alert
        end
      end

      if j.background_check_requested_at.present?
        if closed_jobs == true
          notes_alerts << note("#{j.background_check_requested_at.to_date.strftime("%m/%d/%y")}: Bkgrd Check Sent")
        else
          notes_alerts << note("#{timeAgo(datetime: j.background_check_requested_at.to_datetime)}: Bkgrd Check Sent")
        end
        if j.background_check_completed_at.present?
          if closed_jobs == true
            notes_alerts << note("#{j.background_check_completed_at.to_date.strftime("%m/%d/%y")}: Bkgrd Check Done")
          else
            notes_alerts << note("#{timeAgo(datetime: j.background_check_completed_at.to_datetime)}: Bkgrd Check Done")
          end
        else
          notes_alerts << noteLatest("Pending: Bkgrd Check")
          alert = alertForBkgrdNotComplete(datetime: job_created_at.to_datetime)
          if alert.present?
            notes_alerts << alert
          end
        end
      # NOTE: It is no longer guarenteed that we'll see this action, due to new 3rd party service used.
      # elsif j.last_offer_sent_at.present?
      #   notes_alerts << alertLevelTwo("Missing: Bkgrd Check Request")
      end

      if j.hired_at.present?
        time_to_start = (j.hired_at.to_datetime - job_created_at.to_datetime).to_i
        if closed_jobs == true
          notes_alerts << note("#{j.hired_at.to_date.strftime("%m/%d/%y")}: Hired")
        else
          notes_alerts << noteLatest("#{timeAgo(datetime: j.hired_at.to_datetime)}: Hired")
        end
      elsif j.offer_accepted_at.present? && j.background_check_completed_at.present?
        notes_alerts << noteLatest("Pending: Hire")
      end

      if closed_jobs == false
        if j.last_activity_member_datetime.present?
          alert = alertForNoMemberActivity(datetime: j.last_activity_member_datetime.to_datetime)
          if alert.present?
            notes_alerts << alert
          end
        else  
          alert = alertForNoMemberActivity(datetime: j.job_created_at.to_datetime)
          if alert.present?
            notes_alerts << alert
          end
        end
  
        if j.last_activity_candidate_datetime.present?
          alert = alertForNoCandidateActivity(datetime: j.last_activity_candidate_datetime.to_datetime)
          if alert.present?
            notes_alerts << alert
          end
        else  
          alert = alertForNoCandidateActivity(datetime: job_created_at.to_datetime)
          if alert.present?
            notes_alerts << alert
          end
        end
      end

      # Team, if exists
      if j.property.team.present?
        team = j.property.team.code
      else 
        team = '' # For sorting purposes
      end

      backend_url = nil
      if closed_jobs == false
        if j.url.present?
          backend_url = j.url.sub('jobs', 'backend/jobs').concat('/browser')
        end
      end
      
      # Look up user from last_activity_member_name
      if j.last_activity_member_name.present?
        member_name_array = j.last_activity_member_name.split(" ")
        if member_name_array.length >= 2
          cobalt_user = User.where('lower(first_name) = ?', member_name_array[0].downcase)
                            .where('lower(last_name) = ?', member_name_array[1].downcase).first
        end
      end
      if cobalt_user.present?
        # TODO: Use an ENV variable to set Team ID for slack
        # slack://user?team=T0532D0A4&id=U4EK1071N
        if cobalt_user.slack_username.present?
          team_id = ENV.fetch('SLACK_TEAM_ID')
          slack_dm_url = "slack://user?team=#{team_id}&id=#{cobalt_user.slack_username}"
        end
        if cobalt_user.profile_image.present?
          last_activity_member_profile_image = cobalt_user.profile_image
        end
      end

      team_logo = nil
      if j.property.present? && j.property.team.present?
        team_logo = j.property.team.logo
      end
      if j.property.present? && j.property.type == 'Team'
        team_logo = j.property.logo
      end

      employment = employment_length_data(job: j)

      acceptance = acceptance_data(job: j)

      code = nil
      type = nil
      property_image = nil
      if j.property.present?
        code = j.property.code
        type = j.property.type
        property_image = j.property.image
      end

      {
        :job_created_at => job_created_at,
        # :url => j.url,
        :url => backend_url,
        :team => team,
        :code => code,
        :type => type,
        :title => title,
        :title_bkg_color => title_bkg_color,
        :state => j.state,
        :date_opened => date_opened,
        :days_open => days_open,
        :property_image => property_image,
        :team_logo => team_logo,
        :last_activity_member_slack_dm_url => slack_dm_url,
        :last_activity_member_profile_image => last_activity_member_profile_image,
        :last_activity_member_name => j.last_activity_member_name,
        :last_activity_member_date => last_activity_member_date,
        :last_activity_member_action => j.last_activity_member_action,
        :last_activity_member_stage_name => j.last_activity_member_stage_name,
        :last_activity_candidate_date => last_activity_candidate_date,
        :last_activity_candidate_action => j.last_activity_candidate_action,
        :last_activity_candidate_stage_name => j.last_activity_candidate_stage_name,
        :time_to_fill => time_to_fill,
        :time_to_start => time_to_start,
        :notes_alerts => notes_alerts,
        :employee_date_in_job => employment[:employee_date_in_job],
        :employee_date_last_worked => employment[:employee_date_last_worked],
        :employee_date_last_worked_color => employment[:employee_date_last_worked_color],
        :employee_date_last_worked_bkg_color => employment[:employee_date_last_worked_bkg_color],
        :employee_days_from_start => employment[:employee_days_from_start],
        :employee_days_in_job => employment[:employee_days_in_job],
        :employee_days_in_job_string => employment[:employee_days_in_job_string],
        :employee_active => employment[:employee_active],
        :acceptance_percentage => acceptance[:acceptance_percentage],
        :acceptance_percentage_string => acceptance[:acceptance_percentage_string],
        :allow_edit => allow_edit,
        :job_id => j.id
      }
    end
  end

  def separate_jobs_data_by_team(jobs_data)
    if jobs_data.nil? || jobs_data.empty?
      return []
    end

    sorted_jobs_data = jobs_data.sort { |a,b| a[:team] <=> b[:team] }
    teams_array = []
    jobs_for_team_array = []
    current_team = nil
    sorted_jobs_data.each do |job| 
      if current_team != job[:team]
        current_team = job[:team]
        if jobs_for_team_array.count > 0
          teams_array << sort_jobs_data(jobs_for_team_array)
        end
        jobs_for_team_array = []
      end

      jobs_for_team_array << job
    end

    # Add last team
    if jobs_for_team_array.count > 0
      teams_array << sort_jobs_data(jobs_for_team_array)
    end

    return teams_array
  end

  def separate_jobs_by_team(jobs)
    if jobs.nil? || jobs.empty?
      return []
    end

    sort_data = []
    jobs.each do |j|
      if j.property.present? && j.property.team.present?
        team = j.property.team.code
      else 
        team = '' # For sorting purposes
      end

      sort_data << {:team => team, :job => j}
    end

    sorted_data = sort_data.sort { |a,b| a[:team] <=> b[:team] }
    teams_array = []
    jobs_for_team_array = []
    current_team = nil
    sorted_data.each do |data| 
      if current_team != data[:team]
        current_team = data[:team]
        if jobs_for_team_array.count > 0
          teams_array << jobs_for_team_array
        end
        jobs_for_team_array = []
      end

      jobs_for_team_array << data[:job]
    end

    # Add last team
    if jobs_for_team_array.count > 0
      teams_array << jobs_for_team_array
    end

    return teams_array
  end

  def stats_data(jobs:, alerts_enabled:)
    time_to_fill_sum = 0
    time_to_start_sum = 0
    hired_count = 0

    acceptance_sum = 0
    acceptance_count = 0

    employees_employed_over_90_days_ago = 0
    employees_employed_over_90_days = 0

    # employment_in_days_sum = 0
    # employment_in_days_count = 0
    employees_active = 0

    team = ''

    jobs.each do |j| 
      # Only existing Properties/Teams
      if !j.new_property

        if j.offer_accepted_at.present? && j.hired_at.present?
          if j.original_job_created_at.present?
            time_to_fill_sum += (j.offer_accepted_at.to_datetime - j.original_job_created_at.to_datetime).to_i
            time_to_start_sum += (j.hired_at.to_datetime - j.original_job_created_at.to_datetime).to_i
          else
            time_to_fill_sum += (j.offer_accepted_at.to_datetime - j.job_created_at.to_datetime).to_i
            time_to_start_sum += (j.hired_at.to_datetime - j.job_created_at.to_datetime).to_i
          end
          hired_count += 1
        end 
  
        acceptance = acceptance_data(job: j)
  
        if acceptance[:acceptance_percentage].present?
          acceptance_sum += acceptance[:acceptance_percentage]
          acceptance_count += 1
        end
  
        unless j.employee_ignore 
          employment = employment_length_data(job: j)
  
          if employment[:employee_days_from_start].present? && employment[:employee_days_in_job].present?
            if employment[:employee_days_from_start] > 90
              puts "started: #{employment[:employee_days_from_start]}, days: #{employment[:employee_days_in_job]}"
              employees_employed_over_90_days_ago += 1
              if employment[:employee_days_in_job] > 90
                employees_employed_over_90_days += 1
              end
            end
            # employment_in_days_sum += employment[:employee_days_in_job]
            # employment_in_days_count += 1
            if employment[:employee_active] == true
              employees_active += 1
            end
          end
        end
      end

      if team == '' && j.property.present? && j.property.team.present?
        team = j.property.team.code
      end
    end

    avg_time_to_fill_color = "white"
    avg_time_to_start_color = "white"

    if hired_count > 0
      avg_time_to_fill = number(time_to_fill_sum / hired_count)
      avg_time_to_start = number(time_to_start_sum / hired_count)
      if alerts_enabled
        if time_to_fill_sum / hired_count > 30
          avg_time_to_fill_color = "alert"
        end
        if time_to_start_sum / hired_count > 45
          avg_time_to_start_color = "alert"
        end   
      end
    else
      avg_time_to_fill = "--"
      avg_time_to_start = "--"
    end

    if acceptance_count > 0
      avg_acceptance = number(acceptance_sum / acceptance_count)
    else
      avg_acceptance = "--"
    end

    # if employment_in_days_count > 0
    #   avg_employment_in_days = number(employment_in_days_sum / employment_in_days_count)
    # else
    #   avg_employment_in_days = "--"
    # end

    if employees_employed_over_90_days_ago > 0
      employed_ninty_plus_days = ((employees_employed_over_90_days.to_d / employees_employed_over_90_days_ago.to_d) * 100.0).to_i
    else 
      employed_ninty_plus_days = "--"
    end  

    {
      :team => team,
      :hired_count => hired_count,
      :avg_time_to_fill => avg_time_to_fill,
      :avg_time_to_start => avg_time_to_start,
      :avg_time_to_fill_color => avg_time_to_fill_color,
      :avg_time_to_start_color => avg_time_to_start_color,
      :avg_acceptance => avg_acceptance,
      :employed_ninty_plus_days => employed_ninty_plus_days,
      :employees_employed_over_90_days_ago => employees_employed_over_90_days_ago,
      :employees_active => employees_active
      # :avg_employment_in_days => avg_employment_in_days,
    }
  end

  def employment_length_data(job: )
    employee_active = false
    employee_date_in_job = 'No Match'
    employee_days_from_start = nil
    if job.employee_date_in_job.present?
      employee_date_in_job = job.employee_date_in_job.to_date.strftime("%m/%d/%y")
      employee_days_from_start = (DateTime.now - job.employee_date_in_job.to_datetime).to_i
    end
    employee_date_last_worked = 'No Match'
    end_datetime = nil
    employee_date_last_worked_color = 'off_white'
    employee_date_last_worked_bkg_color = 'transparent '
    if job.employee_date_last_worked.present?
      employee_date_last_worked = job.employee_date_last_worked.to_date.strftime("%m/%d/%y")
      end_datetime = job.employee_date_last_worked.to_datetime
      employee_date_last_worked_color = 'white'
      employee_date_last_worked_bkg_color = 'red'
    elsif job.employee_date_in_job.present? && job.employee.present?
      if job.employee_date_in_job == job.employee.date_in_job
        employee_date_last_worked = 'Present'
        end_datetime = DateTime.now
        employee_active = true
      elsif job.employee_updated_at.present?
        # Assume they transferred
        employee_date_last_worked = job.employee_updated_at.to_date.strftime("%m/%d/%y")
        end_datetime = job.employee_updated_at.to_datetime
      else  
        employee_date_last_worked = 'Unknown'
      end
    end
    employee_days_in_job = nil
    employee_days_in_job_string = ''
    if job.employee_ignore 
      employee_days_in_job_string = "IGNORED"
    elsif job.employee_date_in_job.present? && end_datetime.present?
      employee_days_in_job = (end_datetime - job.employee_date_in_job.to_datetime).to_i
      employee_days_in_job_string = "#{employee_days_in_job} Days"
    end

    {
      :employee_date_in_job => employee_date_in_job,
      :employee_date_last_worked => employee_date_last_worked,
      :employee_date_last_worked_color => employee_date_last_worked_color,
      :employee_date_last_worked_bkg_color => employee_date_last_worked_bkg_color,
      :employee_days_from_start => employee_days_from_start,
      :employee_days_in_job => employee_days_in_job,
      :employee_days_in_job_string => employee_days_in_job_string,
      :employee_active => employee_active
    }
  end

  def acceptance_data(job: )
    acceptance_percentage = nil
    acceptance_percentage_string = 'Acceptance: NA'
    if job.offer_accepted_at.present? && job.hired_at.present? && job.num_of_offers_sent.present? && job.num_of_offers_sent > 0
      acceptance_percentage = (1.0 / (job.num_of_offers_sent.to_f + job.other_num_of_offers_sent.to_f)) * 100.0
      acceptance_percentage_string = "Acceptance: #{acceptance_percentage.round}%"
    end

    {
      :acceptance_percentage => acceptance_percentage,
      :acceptance_percentage_string => acceptance_percentage_string
    }
  end

  def sort_jobs_data(jobs_data)
    if jobs_data.nil? || jobs_data.empty?
      return []
    end
    
    case @sort_option_selected
    when @sort_options[0] # Days Open
      jobs_data.sort { |a,b| a[:job_created_at] <=> b[:job_created_at] }
    when @sort_options[1] # Job Title
      jobs_data.sort { |a,b| a[:title] <=> b[:title] }
    when @sort_options[2] # Region/Property
      jobs_data.sort_by { |job| [Property.get_code_position(job[:code], job[:type]), job[:code]]  }
      # jobs_data.sort { |a,b| a[:code] <=> b[:code] }
    else
      jobs_data.sort { |a,b| a[:job_created_at] <=> b[:job_created_at] }
    end
  end

  def number(value)
    number_with_precision(value, precision: 0, strip_insignificant_zeros: true)  
  end

  def money(value)
    number_to_currency(value, precision: 2, strip_insignificant_zeros: false)  
  end

  def money_only_dolars(value)
    number_to_currency(value, precision: 2, strip_insignificant_zeros: true)  
  end
  
  def percent(value)
    number_to_percentage(value, precision: 0, strip_insignificant_zeros: true)
  end

  def timeAgo(datetime:)
    return distance_of_time_in_words(Time.now, datetime.to_time, compact: true, words_connector: " ", last_word_connector: " ", two_words_connector: " ", accumulate_on: :days, highest_measures: 2) + ' ago'
  end

  def alertForNoOfferSent(datetime:, extended:)
    days_ago = (DateTime.now - datetime).to_i
    if days_ago < 0
      return nil
    end
    
    if extended
      case days_ago
      when 0..30
        return nil
      when 31..45
        return alertLevelOne("#{days_ago} days: No Offer Sent")
      else
        return alertLevelTwo("#{days_ago} days: No Offer Sent")
      end
    else
      case days_ago
      when 0..14
        return nil
      when 15..30
        return alertLevelOne("#{days_ago} days: No Offer Sent")
      else
        return alertLevelTwo("#{days_ago} days: No Offer Sent")
      end
    end
  end

  def alertForNoOfferAccepted(datetime:, extended:)
    days_ago = (DateTime.now - datetime).to_i
    if days_ago < 0
      return nil
    end
    
    if extended
      case days_ago
      when 0..45
        return nil
      when 46..60
        return alertLevelOne("#{days_ago} days: Offer Not Accepted")
      else
        return alertLevelTwo("#{days_ago} days: Offer Not Accepted")
      end
    else
      case days_ago
      when 0..30
        return nil
      when 31..45
        return alertLevelOne("#{days_ago} days: Offer Not Accepted")
      else
        return alertLevelTwo("#{days_ago} days: Offer Not Accepted")
      end
    end

  end

  def alertForBkgrdNotComplete(datetime:)
    days_ago = (DateTime.now - datetime).to_i
    if days_ago < 0
      return nil
    end
    
    case days_ago
    when 0..30
      return nil
    when 31..45
      return alertLevelOne("#{days_ago} days: Bkgrd Not Complete")
    else
      return alertLevelTwo("#{days_ago} days: Bkgrd Not Complete")
    end
  end

  def alertForNoMemberActivity(datetime:)
    days_ago = (DateTime.now - datetime).to_i
    if days_ago < 0
      return nil
    end
    
    case days_ago
    when 0..7
      return nil
    when 8..10
      return alertLevelOne("#{days_ago} days: No Bluestone Activity")
    else
      return alertLevelTwo("#{days_ago} days: No Bluestone Activity")
    end
  end

  def alertForNoCandidateActivity(datetime:)
    days_ago = (DateTime.now - datetime).to_i
    if days_ago < 0
      return nil
    end
    
    case days_ago
    when 0..7
      return nil
    when 8..10
      return alertLevelOne("#{days_ago} days: No Candidate Activity")
    else
      return alertLevelTwo("#{days_ago} days: No Candidate Activity")
    end
  end

  def note(text)
    return { :text => text, :color => "off_white", :bkgrd_color => "transparent" }
  end

  def noteLatest(text)
    return { :text => text, :color => "white", :bkgrd_color => "transparent" }
  end

  def alertLevelOne(text)
    if @alerts_counter_enabled == true
      @alerts_lvl1_count = @alerts_lvl1_count + 1 
    end
    return { :text => text, :color => "white", :bkgrd_color => "darkorange" }
  end

  def alertLevelTwo(text)
    if @alerts_counter_enabled == true
      @alerts_lvl2_count = @alerts_lvl2_count + 1 
    end    
    return { :text => text, :color => "white", :bkgrd_color => "red" }
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_workable_job
      @workable_job = WorkableJob.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def workable_job_params
      params.require(:workable_job).permit(:employee_first_name_override, :employee_last_name_override, :employee_ignore)
    end


end
