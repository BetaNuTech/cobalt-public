# == Schema Information
#
# Table name: trm_blue_shifts
#
#  id                                  :integer          not null, primary key
#  property_id                         :integer
#  metric_id                           :integer
#  user_id                             :integer
#  created_on                          :date
#  manager_problem                     :boolean
#  manager_problem_details             :text
#  manager_problem_fix                 :text
#  manager_problem_results             :text
#  manager_problem_fix_by              :date
#  market_problem                      :boolean
#  market_problem_details              :text
#  marketing_problem                   :boolean
#  marketing_problem_details           :text
#  marketing_problem_fix               :text
#  marketing_problem_fix_by            :date
#  capital_problem                     :boolean
#  capital_problem_details             :text
#  archived                            :boolean
#  archived_status                     :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  archive_edit_user_id                :integer
#  initial_archived_status             :string
#  archive_edit_date                   :date
#  comment_thread_id                   :integer
#  manager_problem_comment_thread_id   :integer
#  market_problem_comment_thread_id    :integer
#  marketing_problem_comment_thread_id :integer
#  capital_problem_comment_thread_id   :integer
#  initial_archived_date               :date
#  vp_reviewed                         :boolean
#
class TrmBlueShift < ActiveRecord::Base
  ARCHIVED_STATUSES = ["success", "failure"]
  
  acts_as_commontable
  audited only: [
    :manager_problem, :manager_problem_details, :manager_problem_fix, :manager_problem_fix_by, :manager_problem_results,
    :market_problem, :market_problem_details,
    :capital_problem, :capital_problem_details,
    :marketing_problem, :marketing_problem_details, :marketing_problem_fix, :marketing_problem_fix_by,
    :archived, :archived_status, :vp_reviewed
  ], on: [:update]
  
  belongs_to :property
  belongs_to :user
  belongs_to :metric
  belongs_to :archive_edit_user, class_name: 'User', optional: true
  
  belongs_to :comment_thread, class_name: "Commontator::Thread", autosave: true,
    dependent: :destroy
  belongs_to :manager_problem_comment_thread, class_name: "Commontator::Thread", 
    autosave: true, dependent: :destroy
  belongs_to :market_problem_comment_thread, class_name: "Commontator::Thread", 
    autosave: true, dependent: :destroy
  belongs_to :marketing_problem_comment_thread, class_name: "Commontator::Thread", 
    autosave: true, dependent: :destroy
  belongs_to :capital_problem_comment_thread, class_name: "Commontator::Thread", 
    autosave: true, dependent: :destroy 
      
  attr_accessor :current_user
  # attr_accessor :archive_edit_user
  
  validates :property, presence: true
  validates :user, presence: true
  validates :metric, presence: true
  validates :created_on, presence: true
  validates :archived, inclusion: { in: [true, false] }
  validates :archived_status, inclusion: { in: ARCHIVED_STATUSES }, if: :archived
  validates :manager_problem, inclusion: { in: [true, false] }
  validates :market_problem, inclusion: { in: [true, false] }
  validates :marketing_problem, inclusion: { in: [true, false] }
  validates :capital_problem, inclusion: { in: [true, false] }
  
  validates :manager_problem_fix, presence: true, if: :manager_problem
  validates :marketing_problem_fix, presence: true, if: :marketing_problem
  
  validates :manager_problem_fix_by, presence: true, if: :manager_problem
  validates :marketing_problem_fix_by, presence: true, if: :marketing_problem
  
  validate :valid_manager_problem_fix_by_date?
  validate :valid_marketing_problem_fix_by_date?

  validate :valid_answers_set?
  
  validates :manager_problem_comment_thread, presence: true
  validates :market_problem_comment_thread, presence: true
  validates :marketing_problem_comment_thread, presence: true
  validates :capital_problem_comment_thread, presence: true
  
  validates :manager_problem_details, presence: { if: :manager_problem, message: 'must be entered.' }
  validates :marketing_problem_details, presence: { if: :marketing_problem, message: 'must be entered.' }
  
  before_validation :default_values
  before_validation :set_comment_threads
  after_update :send_alerts_for_fix_by_date_changes
  after_update :send_alerts_for_results_changes

  after_commit :send_notification_for_created_trm_blueshift, on: :create
  after_commit :send_notification_for_updated_trm_blueshift, on: :update
  
  def latest_fix_by_date
    dates = []
    dates << manager_problem_fix_by if manager_problem_fix_by.present?
    dates << marketing_problem_fix_by if marketing_problem_fix_by.present?
    
    dates.sort! 
    
    latest_date = dates.last
    if latest_date.nil?
      latest_date = created_on + 3.weeks
    end

    return latest_date
  end

  def valid_answers_set?
    if !manager_problem && !market_problem && !marketing_problem && !capital_problem
      errors.add("At least one problem required to be true.")
    end
  end

  def valid_manager_problem_fix_by_date?
    unless manager_problem_fix_by.nil? or created_on.nil? or manager_problem_fix_by <= (created_on + 3.weeks)
      errors.add(:manager_problem_fix_by, "has to be no more than 3 weeks out, from trm blueshift creation date")
    end
    if manager_problem_fix_by.present? && manager_problem_fix_by >= Date.today
      errors.add(:manager_problem_fix_by, "can't be in the past")
    end
  end

  def valid_marketing_problem_fix_by_date?
    unless marketing_problem_fix_by.nil? or created_on.nil? or marketing_problem_fix_by <= (created_on + 3.weeks)
      errors.add(:marketing_problem_fix_by, "has to be no more than 3 weeks out, from trm blueshift creation date")
    end
    if marketing_problem_fix_by.present? && marketing_problem_fix_by >= Date.today
      errors.add(:marketing_problem_fix_by, "can't be in the past")
    end
  end
  
  def any_fix_by_date_expired?
    return (date_expired?(manager_problem_fix_by) or 
      date_expired?(marketing_problem_fix_by))
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
    latest_metrics = TrmBlueShift.latest_metrics_for_success(property, date)
    if latest_metrics.nil? || latest_metrics.count == 0
      return false
    end

    return !Metric.trm_blueshift_form_needed?(latest_metrics)
  end

  def send_message_if_vp_review_needed
    if !archived && !vp_reviewed
      # Monica Escobedo (Corp)
      mentions = "<@UH2BFC2JG>"
      message = "*`#{property.code}`* -> #{mentions}: VP Review required for TRM blueshift. Please review and check *VP Reviewed*. #{url_to_trm_blueshift()}"   
      channel = TrmBlueShift.trm_blueshift_channel() 
      send_slack_alert(channel, message)
    end
  end
  
  private

  def current_metric
    return Metric.where(property: property).where(main_metrics_received: true).order("date DESC").first
  end

  def set_comment_threads
    self.comment_thread ||= Commontator::Thread.new(commontable: self, commontable_type: "TrmBlueShift")
    self.manager_problem_comment_thread ||= Commontator::Thread.new(commontable: self, commontable_type: "TrmBlueShift")
    self.market_problem_comment_thread ||= Commontator::Thread.new(commontable: self, commontable_type: "TrmBlueShift")
    self.marketing_problem_comment_thread ||= Commontator::Thread.new(commontable: self, commontable_type: "TrmBlueShift")
    self.capital_problem_comment_thread ||= Commontator::Thread.new(commontable: self, commontable_type: "TrmBlueShift")
    
    return true
  end
  
  def default_values
    if self.new_record?
      self.archived ||= false
    end
    
    return true
  end
  
  def date_expired?(date)
    return false if date.blank?
    
    return date < Time.now.to_date
  end

  ##################
  # Notifications #
  ##################

  def self.trm_blueshift_channel
    return '#trm-blueshifts'
  end

  def send_alerts_for_results_changes
    ["manager"].each do |problem|
      send_alert_for_results_change(problem)
    end
  end

  def send_alerts_for_fix_by_date_changes
    ["manager", "marketing"].each do |problem|
      send_alert_for_fix_by_date_change(problem)
    end
  end

  def send_alert_for_results_change(problem)
    if self.send("#{problem}_problem") && self.send("#{problem}_problem_results_changed?") 
      message = "*`#{property.code}`* -> #{problem.capitalize} Problem Results Updated:\n```#{self.send("#{problem}_problem_results")}```"
    
      unless property.slack_channel.nil?
        channel = TrmBlueShift.trm_blueshift_channel()
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

      mentions = slack_mentions()
      message = "*`#{property.code}`* -> " + mentions + ": " + message

      channel = TrmBlueShift.trm_blueshift_channel()
      send_slack_alert(channel, message)
    end    
  end
  
  def alert_fix_by_date_message(problem, original_date, new_date)
    I18n.t('alerts.trm_blue_shifts.fix_by_date_update', problem: problem,
      property: self.property.code,
      user: @current_user.present? ? @current_user.name : 'unknown',
      original_date: original_date.strftime("%m/%d/%Y"), new_date: new_date.strftime("%m/%d/%Y"),
      trm_blue_shift_url: url_to_trm_blueshift) 
  end

  def url_to_trm_blueshift
    Rails.application.routes.url_helpers.property_trm_blue_shift_url(self.property, self)
  end

  def send_notification_for_created_trm_blueshift
    send_notification_for_trm_blueshift(false)
  end

  def send_notification_for_updated_trm_blueshift
    send_notification_for_trm_blueshift(true)
  end

  def send_notification_for_trm_blueshift(updated)

    blueshift_type = 'TRM Blueshift'
    problems = []

    if manager_problem
      problems << "`MANAGER PROBLEM`"
    end
    if market_problem
      problems << "`MARKET PROBLEM`"
    end 
    if marketing_problem
      problems << "`MARKETING PROBLEM`"
    end 
    if capital_problem
      problems << "`CAPITAL PROBLEM`"
    end

    mentions = slack_mentions()

    user_name = user.slack_corp_username
    if user_name.nil? || user_name == ""
      user_name = "*#{user.first_name} #{user.last_name}*"
    else
      user_name = "<@#{user_name}>"
    end

    problems_string = problems.join("  ")
  
    due_date = latest_fix_by_date()

    if updated
      if archived
        if due_date.nil?
          message = "*`#{property.code}`* -> #{mentions}: A *#{blueshift_type}* created on *#{created_on}* by #{user_name} was just `archived` with status `#{archived_status}`. Selections: #{problems_string}" 
        else
          message = "*`#{property.code}`* -> #{mentions}: A *#{blueshift_type}* created on *#{created_on}* by #{user_name} was just `archived` with status `#{archived_status}`. The due date was `#{due_date}`, with #{problems_string} selected." 
        end
      else
        if due_date.nil?        
          message = "*`#{property.code}`* -> #{mentions}: A *#{blueshift_type}* created on *#{created_on}* by #{user_name} was just `updated` with *#{problems_string}* selected. #{url_to_trm_blueshift}"    
        else
          message = "*`#{property.code}`* -> #{mentions}: A *#{blueshift_type}* created on *#{created_on}* by #{user_name} was just `updated` with *#{problems_string}* selected. Due date is currently set to `#{due_date}`. #{url_to_trm_blueshift}"    
        end
      end
    else
      if due_date.nil?  
        message = "*`#{property.code}`* -> #{mentions}: #{user_name} has `created` a *#{blueshift_type}* with *#{problems_string}* selected. #{url_to_trm_blueshift}"          
      else
        message = "*`#{property.code}`* -> #{mentions}: #{user_name} has `created` a *#{blueshift_type}* with *#{problems_string}* selected. Due date is currently set to `#{due_date}`. #{url_to_trm_blueshift}"    
      end
    end

    channel = TrmBlueShift.trm_blueshift_channel()
    send_slack_alert(channel, message)

    if !updated
      send_message_if_vp_review_needed()
    end
  end

  def send_slack_alert(slack_channel, message)
    if slack_channel.include? 'test'
      message.sub! '@', ''
    end 
    send_alert = 
      Alerts::Commands::SendCorpBlueBotSlackMessage.new(message, slack_channel)
    Job.create(send_alert)      
  end

  def slack_mentions()
    # Monica Escobedo (Corp)
    mentions = "<@UH2BFC2JG>"

    # TODO: Support corporate usernames
    trm_mention = property.corp_talent_resource_manager_mention(user)
    if trm_mention != ""
      mentions += " #{trm_mention}"
    end

    return mentions
  end

end
