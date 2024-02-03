# == Schema Information
#
# Table name: blue_shifts
#
#  id                                                  :integer          not null, primary key
#  property_id                                         :integer
#  created_on                                          :date
#  people_problem                                      :boolean
#  people_problem_fix                                  :text
#  people_problem_fix_by                               :date
#  product_problem                                     :boolean
#  product_problem_fix                                 :text
#  product_problem_fix_by                              :date
#  pricing_problem                                     :boolean
#  pricing_problem_fix                                 :text
#  pricing_problem_fix_by                              :date
#  need_help                                           :boolean
#  need_help_with                                      :text
#  created_at                                          :datetime         not null
#  updated_at                                          :datetime         not null
#  user_id                                             :integer
#  comment_thread_id                                   :integer
#  people_problem_comment_thread_id                    :integer
#  product_problem_comment_thread_id                   :integer
#  pricing_problem_comment_thread_id                   :integer
#  need_help_comment_thread_id                         :integer
#  archived                                            :boolean
#  archived_status                                     :string
#  metric_id                                           :integer
#  no_people_problem_reason                            :text
#  no_people_problem_checked                           :boolean
#  archive_edit_user_id                                :integer
#  initial_archived_status                             :string
#  archive_edit_date                                   :date
#  reviewed                                            :boolean          default(FALSE)
#  people_problem_reason_all_office_staff              :boolean          default(FALSE)
#  people_problem_reason_short_staffed                 :boolean          default(FALSE)
#  people_problem_reason_specific_people               :boolean          default(FALSE)
#  people_problem_specific_people                      :text
#  people_problem_details                              :text
#  product_problem_reason_curb_appeal                  :boolean          default(FALSE)
#  product_problem_reason_unit_make_ready              :boolean          default(FALSE)
#  product_problem_reason_maintenance_staff            :boolean          default(FALSE)
#  product_problem_details                             :text
#  product_problem_specific_people                     :text
#  initial_archived_date                               :date
#  people_problem_fix_results                          :text
#  product_problem_fix_results                         :text
#  archived_failure_reasons                            :string
#  need_help_marketing_problem                         :boolean
#  need_help_marketing_problem_marketing_reviewed      :boolean
#  need_help_capital_problem                           :boolean
#  need_help_capital_problem_explained                 :text
#  need_help_capital_problem_asset_management_reviewed :boolean
#  need_help_capital_problem_maintenance_reviewed      :boolean
#  basis_triggered_value                               :decimal(, )
#  trending_average_daily_triggered_value              :decimal(, )
#  physical_occupancy_triggered_value                  :decimal(, )
#  pricing_problem_denied                              :boolean          default(FALSE)
#  pricing_problem_approved                            :boolean          default(FALSE)
#  pricing_problem_approved_cond                       :boolean          default(FALSE)
#  pricing_problem_approved_cond_text                  :text
#
class BlueShift < ActiveRecord::Base
  ARCHIVED_STATUSES = ["success", "failure"]
  
  acts_as_commontable
  audited only: [
    :people_problem, :people_problem_fix, :people_problem_fix_by,    
    :product_problem, :product_problem_fix, :product_problem_fix_by,    
    :pricing_problem, :pricing_problem_fix, :pricing_problem_fix_by,
    :people_problem_reason_all_office_staff, :people_problem_reason_short_staffed, :people_problem_reason_specific_people,
    :product_problem_reason_curb_appeal, :product_problem_reason_unit_make_ready, :product_problem_reason_maintenance_staff,
    :people_problem_specific_people, :people_problem_details, :product_problem_specific_people, :product_problem_details,
    :people_problem_fix_results, :product_problem_fix_results,
    :need_help, :need_help_with,
    :need_help_marketing_problem, :need_help_capital_problem, :need_help_capital_problem_explained,
    :reviewed, :need_help_marketing_problem_marketing_reviewed, :need_help_capital_problem_asset_management_reviewed, :need_help_capital_problem_maintenance_reviewed, :pricing_problem_denied, :pricing_problem_approved, :pricing_problem_approved_cond, :pricing_problem_approved_cond_text,
    :archived, :archived_status 
  ], on: [:update]
  
  belongs_to :property
  belongs_to :user
  belongs_to :metric
  belongs_to :archive_edit_user, class_name: 'User', optional: true
  
  belongs_to :comment_thread, class_name: "Commontator::Thread", autosave: true,
    dependent: :destroy
  belongs_to :people_problem_comment_thread, class_name: "Commontator::Thread", 
    autosave: true, dependent: :destroy
  belongs_to :product_problem_comment_thread, class_name: "Commontator::Thread", 
    autosave: true, dependent: :destroy
  belongs_to :pricing_problem_comment_thread, class_name: "Commontator::Thread", 
    autosave: true, dependent: :destroy
  belongs_to :need_help_comment_thread, class_name: "Commontator::Thread", 
    autosave: true, dependent: :destroy 
  
  has_many :pricing_problem_images, as: :imageable, class_name: "Image", 
    :dependent => :destroy
    
  attr_accessor :current_user
  # attr_accessor :archive_edit_user
  
  validates :property, presence: true
  validates :user, presence: true
  validates :metric, presence: true
  validates :created_on, presence: true
  validates :archived, inclusion: { in: [true, false] }
  validates :archived_status, inclusion: { in: ARCHIVED_STATUSES }, if: :archived
  validates :people_problem, inclusion: { in: [true, false] }
  validates :product_problem, inclusion: { in: [true, false] }
  validates :pricing_problem, inclusion: { in: [true, false] }
  validates :need_help, inclusion: { in: [true, false] }
  validates :need_help, presence: true, if: -> { !people_problem && !product_problem && !pricing_problem }
  validates :need_help_marketing_problem, inclusion: { in: [true, false] }
  validates :need_help_capital_problem, inclusion: { in: [true, false] }
  validates :need_help_with, presence: true, if: :need_help
  validates :need_help_capital_problem_explained, presence: true, if: :need_help_capital_problem
  
  validates :people_problem_fix, presence: true, if: :people_problem
  validates :product_problem_fix, presence: true, if: :product_problem
  validates :pricing_problem_fix, presence: true, if: :pricing_problem
  
  validates :people_problem_fix_by, presence: true, if: :people_problem
  validates :no_people_problem_reason, presence: true, if: -> { !people_problem && created_on && created_on > Date.new(2017,10,20) }
  validates :no_people_problem_checked, presence: { if: -> { !people_problem && created_on && created_on > Date.new(2017,10,20) }, message: 'must be checked.' }
  validates :product_problem_fix_by, presence: true, if: :product_problem
  # validates :pricing_problem_fix_by, presence: true, if: :pricing_problem
  
  validate :valid_people_problem_fix_by_date?
  validate :valid_product_problem_fix_by_date?
  # validate :valid_pricing_problem_fix_by_date?
  
  validates :people_problem_comment_thread, presence: true
  validates :product_problem_comment_thread, presence: true
  validates :pricing_problem_comment_thread, presence: true
  validates :need_help_comment_thread, presence: true
  
  validates_associated :pricing_problem_images, if: :pricing_problem

  validate :valid_people_people_problem_reasons?
  validate :valid_product_people_problem_reasons?
  validates :people_problem_specific_people, presence: { if: -> { people_problem && people_problem_reason_specific_people }, message: 'must have at least one name.' }
  validates :product_problem_specific_people, presence: { if: -> { product_problem && product_problem_reason_maintenance_staff }, message: 'must have at least one name.' }
  validates :people_problem_details, presence: { if: :people_problem, message: 'must be entered.' }
  validates :product_problem_details, presence: { if: :product_problem, message: 'must be entered.' }
  
  validate :pricing_problem_xor_approved_denied?
  validate :check_pricing_problem_approved_cond_text

  before_validation :default_values
  before_validation :set_comment_threads
  before_validation :update_need_help_values
  before_validation :update_pricing_problem_validation
  before_validation :check_fix_by_dates
  after_update :send_alerts_for_fix_by_date_changes
  after_update :send_alerts_for_fix_results_changes

  after_commit :send_notification_for_created_blueshift, on: :create
  after_commit :send_notification_for_updated_blueshift, on: :update
  
  def latest_fix_by_date
    dates = []
    dates << people_problem_fix_by if (people_problem && people_problem_fix_by.present?)
    dates << product_problem_fix_by if (product_problem && product_problem_fix_by.present?)
    # dates << pricing_problem_fix_by if (pricing_problem && pricing_problem_fix_by.present?)
    
    dates.sort! 
    
    latest_date = dates.last
    if latest_date.nil?
      if created_on.nil?
        latest_date = Date.today + 2.weeks
      else
        latest_date = created_on + 2.weeks
      end
    end

    return latest_date
  end

  def valid_people_problem_fix_by_date?
    unless archived or !people_problem or people_problem_fix_by.nil? or created_on.nil? or (people_problem_fix_by <= (created_on + 2.weeks) or created_on < Date.new(2017,10,20))
      errors.add(:people_problem_fix_by, "has to be no more than 2 weeks out, from blueshift creation date")
    end
    unless archived or !people_problem or people_problem_fix_by.nil? or people_problem_fix_by >= Date.today
      errors.add(:people_problem_fix_by, "has to be set to today or after")
    end
  end

  def valid_product_problem_fix_by_date?
    unless archived or !product_problem or product_problem_fix_by.nil? or created_on.nil? or (product_problem_fix_by <= (created_on + 2.weeks) or created_on < Date.new(2017,10,20))
      errors.add(:product_problem_fix_by, "has to be no more than 2 weeks out, from blueshift creation date")
    end
    unless archived or !product_problem or product_problem_fix_by.nil? or product_problem_fix_by >= Date.today
      errors.add(:product_problem_fix_by, "has to be set to today or after")
    end
  end

  # def valid_pricing_problem_fix_by_date?
  #   unless !pricing_problem or pricing_problem_fix_by.nil? or created_on.nil? or (pricing_problem_fix_by <= (created_on + 2.weeks) or created_on < Date.new(2017,10,20))
  #     errors.add(:pricing_problem_fix_by, "has to be no more than 2 weeks out, from blueshift creation date")
  #   end
  # end

  def valid_people_people_problem_reasons?
    unless created_on <= Date.new(2018,12,12) or !people_problem or people_problem_reason_all_office_staff or people_problem_reason_short_staffed or people_problem_reason_specific_people
      errors.add(:base, "At least one people problem selection needed.")
    end
  end

  def valid_product_people_problem_reasons?
    unless created_on <= Date.new(2018,12,12) or !product_problem or product_problem_reason_curb_appeal or product_problem_reason_unit_make_ready or product_problem_reason_maintenance_staff
      errors.add(:base, "At least one product problem selection needed.")
    end
  end

  def pricing_problem_xor_approved_denied?
    unless (pricing_problem_approved ^ pricing_problem_denied ^ pricing_problem_approved_cond) || (!pricing_problem_approved && !pricing_problem_denied && !pricing_problem_approved_cond)
      errors.add(:base, "Check TRM Approved OR TRM Denied OR TRM Approved w/ Conditions, not more than one.")
    end
  end

  def check_pricing_problem_approved_cond_text
    unless !pricing_problem_approved_cond || (pricing_problem_approved_cond && pricing_problem_approved_cond_text != nil && pricing_problem_approved_cond_text != '')
      errors.add(:base, "TRM Approved w/ Conditions, but missing conditions.")
    end
  end
  
  def need_help_with_no_selected_problems?
    return (need_help and !people_problem and !product_problem and !pricing_problem)
  end
  
  def any_fix_by_date_expired?
    return  ( (people_problem  && date_expired?(people_problem_fix_by)) or 
              (product_problem && date_expired?(product_problem_fix_by)) )
  end

  def self.latest_metrics_for_success(property, date)
    x_rolling_days = Settings.blueshift_x_rolling_days.to_i
    if x_rolling_days <= 0
      x_rolling_days = 5
    end
    
    if date.nil?
      return Metric.where(property: property)
                   .where("date > ?", Date.today - x_rolling_days)
                   .where("date <= ?", Date.today)
                   .where(main_metrics_received: true)
                   .order("date ASC")
    else
      return Metric.where(property: property)
                   .where("date > ?", date - x_rolling_days)
                   .where("date <= ?", date)
                   .where(main_metrics_received: true)
                   .order("date ASC")
    end
  end

  def auto_archive_success?
    date = latest_fix_by_date() + 1.day
    latest_metrics = BlueShift.latest_metrics_for_success(property, date)
    if latest_metrics.nil? || latest_metrics.count == 0
      return false
    end

    # average last X days
    physical_occupancy_success = auto_archive_physical_occupancy_success?(latest_metrics)
    trending_average_daily_success = auto_archive_trending_average_daily_success?(latest_metrics)
    basis_success = auto_archive_basis_success?(latest_metrics)

    return physical_occupancy_success && trending_average_daily_success && basis_success
  end

  def auto_archive_physical_occupancy_success?(latest_metrics)
    if !physical_occupancy_triggered_value.nil?
      average = Metric.average_physical_occupancy(latest_metrics)
      latest_metric = latest_metrics.last
      latest = latest_metric.physical_occupancy
      if average < Metric.blue_shift_success_value_for_physical_occupancy(self, metric) &&
        latest < Metric.blue_shift_success_value_for_physical_occupancy(self, metric)
        return false
      end
    end

    return true
  end

  def auto_archive_trending_average_daily_success?(latest_metrics)
    if !trending_average_daily_triggered_value.nil?
      average = Metric.average_trending_average_daily(latest_metrics)
      latest_metric = latest_metrics.last
      latest = latest_metric.trending_average_daily
      if average < Metric.blue_shift_success_value_for_trending_average_daily(self, metric) &&
        latest < Metric.blue_shift_success_value_for_trending_average_daily(self, metric)
        return false
      end
    end

    return true
  end

  def auto_archive_basis_success?(latest_metrics)
    if !basis_triggered_value.nil?
      average = Metric.average_basis(latest_metrics)
      if average < Metric.blue_shift_success_value_for_basis(self)
        return false
      end
    end

    return true
  end

  def auto_archive_failure_reasons_for_date(date)
    latest_metrics = BlueShift.latest_metrics_for_success(property, date)

    puts "COUNT=#{latest_metrics.count}"

    if latest_metrics.nil? || latest_metrics.count == 0
      return ''
    end

    failure_reasons = ''
    if auto_archive_physical_occupancy_success?(latest_metrics)
      failure_reasons += "O-✅"
    else
      failure_reasons += "O-❌"
    end

    if auto_archive_trending_average_daily_success?(latest_metrics)
      failure_reasons += "T-✅"
    else
      failure_reasons += "T-❌"
    end

    if auto_archive_basis_success?(latest_metrics)
      failure_reasons += "B-✅"
    else
      failure_reasons += "B-❌"
    end

    return failure_reasons
  end

  def send_message_if_review_needed
    unless property.slack_channel.nil?
      if !archived && !reviewed
        mention = slack_mentions(false, true)
        message = "#{mention}: Review required for blueshift. Please review and check *TRM Reviewed*. #{url_to_blueshift}"    
        channel = Property.blshift_slack_channel(property.slack_channel)
        send_slack_alert(channel, message)
      end
      if !archived && pricing_problem && !pricing_problem_approved && !pricing_problem_denied && !pricing_problem_approved_cond
        mention = slack_mentions(false, true)
        message = "#{mention}: Pricing Problem Accepted / Denied required for blueshift. Please review and check either *TRM Accepted (/w or w/o conditions)* OR *TRM Denied*. #{url_to_blueshift}"    
        channel = Property.blshift_slack_channel(property.slack_channel)
        send_slack_alert(channel, message)
      end
    end
  end

  def send_message_if_need_help_marketing_problem_review_needed(notify_trm)
    unless property.slack_channel.nil?
      if !archived && need_help_marketing_problem && !need_help_marketing_problem_marketing_reviewed
        mention = marketing_problem_slack_mentions(notify_trm)
        message = "#{mention}: Marketing Problem Review required for blueshift. #{url_to_blueshift}"    
        channel = property.slack_channel_for_marketing()
        send_slack_alert(channel, message)
      end
    end
  end

  def send_messages_if_need_help_capital_problem_reviews_needed(notify_trm)
    unless property.slack_channel.nil?
      if !archived && need_help_capital_problem && !need_help_capital_problem_maintenance_reviewed
        mention = capital_problem_maint_slack_mentions(notify_trm)
        message = "#{mention}: Capital Problem, Maintenance Review required for blueshift. #{url_to_blueshift}"    
        channel = property.slack_channel_for_capital()
        send_slack_alert(channel, message)
      end
      if !archived && need_help_capital_problem && !need_help_capital_problem_asset_management_reviewed
        mention = capital_problem_asset_management_slack_mentions(true)
        message = "#{mention}: Capital Problem, Asset Management Review required for blueshift. #{url_to_blueshift}"    
        channel = property.slack_channel_for_capital()
        send_slack_alert(channel, message)
      end
    end
  end
  
  private

  def current_metric
    return Metric.where(property: property).where(main_metrics_received: true).order("date DESC").first
  end

  def set_comment_threads
    self.comment_thread ||= Commontator::Thread.new(commontable: self)
    
    # if people_problem == true
      self.people_problem_comment_thread ||= Commontator::Thread.new(commontable: self)
    # end
    
    # if product_problem == true
      self.product_problem_comment_thread ||= Commontator::Thread.new(commontable: self)
    # end
    
    # if pricing_problem == true
      self.pricing_problem_comment_thread ||= Commontator::Thread.new(commontable: self)
    # end
    
    # if need_help == true
      self.need_help_comment_thread ||= Commontator::Thread.new(commontable: self)
    # end

    return true
  end
  
  def default_values
    if self.new_record?
      self.archived ||= false
    end

    self.need_help_marketing_problem ||= false
    self.need_help_capital_problem ||= false
    
    return true
  end

  def update_need_help_values
    if self.need_help.present? && self.need_help == false
      self.need_help_marketing_problem = false
      self.need_help_capital_problem = false
    end
  end

  def update_pricing_problem_validation
    if self.pricing_problem.present? && self.pricing_problem == false
      self.pricing_problem_approved = false
      self.pricing_problem_denied = false
      self.pricing_problem_approved_cond = false
      self.pricing_problem_approved_cond_text = ''
    end

    if self.pricing_problem.present? && self.pricing_problem == true &&
      (self.pricing_problem_approved == true || self.pricing_problem_denied == true)
      self.pricing_problem_approved_cond_text = ''
    end
  end

  def check_fix_by_dates
    if self.people_problem == false
      self.people_problem_fix_by = nil
    end
    if self.product_problem == false
      self.product_problem_fix_by = nil
    end

    self.pricing_problem_fix_by = nil
  end

  def date_expired?(date)
    return false if date.blank?
    
    return date < Time.now.to_date
  end

  ##################
  # Notifications #
  ##################

  def send_alerts_for_fix_results_changes
    ["people", "product"].each do |problem|
      send_alert_for_fix_results_change(problem)
    end
  end

  def send_alerts_for_fix_by_date_changes
    ["people", "product", "pricing"].each do |problem|
      send_alert_for_fix_by_date_change(problem)
    end
  end

  def send_alert_for_fix_results_change(problem)
    if self.send("#{problem}_problem") && self.send("#{problem}_problem_fix_results_changed?") 
      message = "#{problem.capitalize} Problem Results Updated:\n```#{self.send("#{problem}_problem_fix_results")}```"
    
      unless property.slack_channel.nil?
        channel = Property.blshift_slack_channel(property.slack_channel)
        send_slack_alert(channel, message)
      end
    end    
  end
  
  
  def send_alert_for_fix_by_date_change(problem)
    if self.send("#{problem}_problem_fix_by").present? and 
      self.send("#{problem}_problem_fix_by_was").present? and 
      self.send("#{problem}_problem_fix_by_changed?") 
      
      message = alert_fix_by_date_message(problem, 
        self.send("#{problem}_problem_fix_by_was"), 
        self.send("#{problem}_problem_fix_by"))

      mentions = slack_mentions(false, true)
      message = mentions + ": " + message

      unless property.slack_channel.nil?
        channel = Property.blshift_slack_channel(property.slack_channel)
        send_slack_alert(channel, message)
      end
    end    
  end
  
  def alert_fix_by_date_message(problem, original_date, new_date)
    I18n.t('alerts.blue_shifts.fix_by_date_update', problem: problem,
      property: self.property.code,
      user: @current_user.present? ? @current_user.name : 'unknown',
      original_date: original_date.strftime("%m/%d/%Y"), new_date: new_date.strftime("%m/%d/%Y"),
      blue_shift_url: url_to_blueshift) 
  end

  def url_to_blueshift
    Rails.application.routes.url_helpers.property_blue_shift_url(self.property, self)
  end

  def send_notification_for_created_blueshift
    send_notification_for_blueshift(false)
  end

  def send_notification_for_updated_blueshift
    send_notification_for_blueshift(true)
  end

  def send_notification_for_blueshift(updated)

    blueshift_type = 'Blueshift'
    problems = []

    if people_problem
      problems << "`PEOPLE PROBLEM`"
    end
    if product_problem
      problems << "`PRODUCT PROBLEM`"
    end 
    if pricing_problem
      problems << "`PRICING PROBLEM`"
    end 
    if need_help
      problems << "`NEED HELP`"
    end
    
    people_problem_not_selected = false
    product_problem_not_selected = false
    if updated
      if !people_problem && self.send("people_problem_changed?")
        people_problem_not_selected = true
        product_problem_not_selected = !product_problem
      end
      if !product_problem && self.send("product_problem_changed?")
        people_problem_not_selected = !people_problem
        product_problem_not_selected = true
      end
    else
      people_problem_not_selected = !people_problem
      product_problem_not_selected = !product_problem
    end

    if archived
      mentions = slack_mentions(true, updated)
    else
      mentions = slack_mentions(false, updated)
    end

    user_name = user.slack_username
    if user_name.nil? || user_name == ""
      user_name = "*#{user.first_name} #{user.last_name}*"
    else
      user_name = "<@#{user_name}>"
    end

    problems_string = problems.join("  ")
  
    due_date = latest_fix_by_date

    if updated
      if archived
        if due_date.nil?
          message = "#{mentions}: A *#{blueshift_type}* created on *#{created_on}* by #{user_name} was just `archived` with status `#{archived_status}`. Selections: #{problems_string}" 
        else
          message = "#{mentions}: A *#{blueshift_type}* created on *#{created_on}* by #{user_name} was just `archived` with status `#{archived_status}`. The due date was `#{due_date}`, with #{problems_string} selected." 
        end
      else
        if due_date.nil?        
          message = "#{mentions}: A *#{blueshift_type}* created on *#{created_on}* by #{user_name} was just `updated` with *#{problems_string}* selected. Please review and respond where appropriate. #{url_to_blueshift}"    
        else
          message = "#{mentions}: A *#{blueshift_type}* created on *#{created_on}* by #{user_name} was just `updated` with *#{problems_string}* selected. Due date is currently set to `#{due_date}`. Please review and respond where appropriate. #{url_to_blueshift}"    
        end
      end
    else
      if due_date.nil?  
        message = "#{mentions}: #{user_name} has `created` a *#{blueshift_type}* with *#{problems_string}* selected. Please review and respond where appropriate. #{url_to_blueshift}"          
      else
        message = "#{mentions}: #{user_name} has `created` a *#{blueshift_type}* with *#{problems_string}* selected. Due date is currently set to `#{due_date}`. Please review and respond where appropriate. #{url_to_blueshift}"    
      end
    end

    unless property.slack_channel.nil?
      channel = Property.blshift_slack_channel(property.slack_channel)
      send_slack_alert(channel, message)

      # Send site visit message to TRM, if necessary
      if people_problem_not_selected && product_problem_not_selected
        mentions = slack_mentions(false, true)
        message = "#{mentions}: No people problem, and no product problem selected; TRM alert to visit property."
        send_slack_alert(channel, message)
      end
    end

    if !updated
      send_message_if_review_needed()
      send_message_if_need_help_marketing_problem_review_needed(true)
      send_messages_if_need_help_capital_problem_reviews_needed(true)
    end
  end

  def send_slack_alert(slack_channel, message)
    if slack_channel.include? 'test'
      message.sub! '@', ''
    end 
    send_alert = 
      Alerts::Commands::SendBlueShiftSlackMessage.new(message, slack_channel)
    Job.create(send_alert)      
  end

  def slack_mentions(corporate_mention, trm_only)
    if corporate_mention
      # Monica Escobedo
      mentions = "<@UH2SD86H3>"
    else
      mentions = ""
    end

    if !trm_only
      mentions += property.property_manager_mentions(user)
    end

    trm_mention = property.talent_resource_manager_mention(user)
    if trm_mention != ""
      mentions += " #{trm_mention}"
    end

    return mentions
  end

  def marketing_problem_slack_mentions(include_trm)
    # Julie Halsey
    mentions = "<@U01138AEG7Q>"

    if include_trm
      trm_mention = property.talent_resource_manager_mention(user)
      if trm_mention != ""
        mentions += " (#{trm_mention})"
      end
    end

    return mentions
  end

  def capital_problem_maint_slack_mentions(include_trm)
    # James Franklin (jfranklin)
    mentions = "<@U6XA58JSE>"

    if include_trm
      trm_mention = property.talent_resource_manager_mention(user)
      if trm_mention != ""
        mentions += " #{trm_mention}"
      end
    end

    return mentions
  end

  def capital_problem_asset_management_slack_mentions(include_trm)
    # Pam Fielder (pfielder)
    mentions = "<@U06DKSTLM>"

    if include_trm
      trm_mention = property.talent_resource_manager_mention(user)
      if trm_mention != ""
        mentions += " #{trm_mention}"
      end
    end

    return mentions
  end

end
