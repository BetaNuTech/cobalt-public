# == Schema Information
#
# Table name: maint_blue_shifts
#
#  id                               :integer          not null, primary key
#  property_id                      :integer
#  created_on                       :date
#  people_problem                   :boolean
#  people_problem_fix               :text
#  people_problem_fix_by            :date
#  vendor_problem                   :boolean
#  vendor_problem_fix               :text
#  vendor_problem_fix_by            :date
#  parts_problem                    :boolean
#  parts_problem_fix                :text
#  parts_problem_fix_by             :date
#  need_help                        :boolean
#  need_help_with                   :text
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  user_id                          :integer
#  archived                         :boolean
#  archived_status                  :string
#  metric_id                        :integer
#  comment_thread_id                :integer
#  people_problem_comment_thread_id :integer
#  vendor_problem_comment_thread_id :integer
#  parts_problem_comment_thread_id  :integer
#  need_help_comment_thread_id      :integer
#  archive_edit_user_id             :integer
#  reviewed                         :boolean          default(FALSE)
#  initial_archived_status          :string
#  archive_edit_date                :date
#  initial_archived_date            :date
#
class MaintBlueShift < ActiveRecord::Base
  ARCHIVED_STATUSES = ["success", "failure"]
  
  acts_as_commontable
  audited only: [
    :people_problem, :people_problem_fix, :people_problem_fix_by,    
    :vendor_problem, :vendor_problem_fix, :vendor_problem_fix_by,    
    :parts_problem, :parts_problem_fix, :parts_problem_fix_by,
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
  belongs_to :vendor_problem_comment_thread, class_name: "Commontator::Thread", 
    autosave: true, dependent: :destroy
  belongs_to :parts_problem_comment_thread, class_name: "Commontator::Thread", 
    autosave: true, dependent: :destroy
  belongs_to :need_help_comment_thread, class_name: "Commontator::Thread", 
    autosave: true, dependent: :destroy 
  
  has_many :parts_problem_images, as: :imageable, class_name: "Image", 
    :dependent => :destroy
    
  attr_accessor :current_user
  
  validates :property, presence: true
  validates :user, presence: true
  validates :metric, presence: true
  validates :created_on, presence: true
  validates :archived, inclusion: { in: [true, false] }
  validates :archived_status, inclusion: { in: ARCHIVED_STATUSES }, if: :archived
  validates :people_problem, inclusion: { in: [true, false] }
  validates :vendor_problem, inclusion: { in: [true, false] }
  validates :parts_problem, inclusion: { in: [true, false] }
  validates :need_help, inclusion: { in: [true, false] }
  validates :need_help, presence: true, if: -> { !people_problem && !vendor_problem && !parts_problem }
  validates :need_help_with, presence: true, if: :need_help
  
  validates :people_problem_fix, presence: true, if: :people_problem
  validates :vendor_problem_fix, presence: true, if: :vendor_problem
  validates :parts_problem_fix, presence: true, if: :parts_problem
  
  validates :people_problem_fix_by, presence: true, if: :people_problem
  validates :vendor_problem_fix_by, presence: true, if: :vendor_problem
  validates :parts_problem_fix_by, presence: true, if: :parts_problem
  
  validate :valid_people_problem_fix_by_date?
  validate :valid_vendor_problem_fix_by_date?
  validate :valid_parts_problem_fix_by_date?
  
  validates :people_problem_comment_thread, presence: true
  validates :vendor_problem_comment_thread, presence: true
  validates :parts_problem_comment_thread, presence: true
  validates :need_help_comment_thread, presence: true
  
  validates_associated :parts_problem_images, if: :parts_problem
  
  before_validation :default_values
  before_validation :set_comment_threads
  after_update :send_alerts_for_fix_by_date_changes

  after_commit :send_notification_for_created_blueshift, on: :create
  after_commit :send_notification_for_updated_blueshift, on: :update
  
  def latest_fix_by_date
    dates = []
    dates << people_problem_fix_by if people_problem_fix_by.present?
    dates << vendor_problem_fix_by if vendor_problem_fix_by.present?
    dates << parts_problem_fix_by if parts_problem_fix_by.present?
    
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
    unless people_problem_fix_by.nil? or created_on.nil? or (people_problem_fix_by <= (created_on + 2.weeks) or created_on < Date.new(2017,10,20))
      errors.add(:people_problem_fix_by, "has to be no more than 2 weeks out, from maint blueshift creation date")
    end
    if people_problem_fix_by.present? && people_problem_fix_by >= Date.today
      errors.add(:people_problem_fix_by, "can't be in the past")
    end
  end

  def valid_vendor_problem_fix_by_date?
    unless vendor_problem_fix_by.nil? or created_on.nil? or (vendor_problem_fix_by <= (created_on + 2.weeks) or created_on < Date.new(2017,10,20))
      errors.add(:vendor_problem_fix_by, "has to be no more than 2 weeks out, from maint blueshift creation date")
    end
    if vendor_problem_fix_by.present? && vendor_problem_fix_by >= Date.today
      errors.add(:vendor_problem_fix_by, "can't be in the past")
    end
  end

  def valid_parts_problem_fix_by_date?
    unless parts_problem_fix_by.nil? or created_on.nil? or (parts_problem_fix_by <= (created_on + 2.weeks) or created_on < Date.new(2017,10,20))
      errors.add(:parts_problem_fix_by, "has to be no more than 2 weeks out, from maint blueshift creation date")
    end
    if parts_problem_fix_by.present? && parts_problem_fix_by >= Date.today
      errors.add(:parts_problem_fix_by, "can't be in the past")
    end
  end
  
  def need_help_with_no_selected_problems?
    return (need_help and !people_problem and !vendor_problem and !parts_problem)
  end
  
  def any_fix_by_date_expired?
    return (date_expired?(people_problem_fix_by) or 
      date_expired?(vendor_problem_fix_by) or 
      date_expired?(parts_problem_fix_by))
  end

  def send_review_needed_message
    unless property.slack_channel.nil?
      mention = slack_mentions(false, true)
      message = "#{mention}: Review required for maintenance blueshift. Please review and check *TRS Reviewed*. #{url_to_maint_blueshift}"    
      channel = Property.blshift_slack_channel(property.slack_channel)
      send_slack_alert(channel, message)
    end
  end
  
  private
  def set_comment_threads
    if self.comment_thread.nil?
      self.comment_thread = Commontator::Thread.new(commontable: self, commontable_type: "MaintBlueShift")
    end
    
    self.people_problem_comment_thread ||= Commontator::Thread.new(commontable: self, commontable_type: "MaintBlueShift")
    
    self.vendor_problem_comment_thread ||= Commontator::Thread.new(commontable: self, commontable_type: "MaintBlueShift")
    
    self.parts_problem_comment_thread ||= Commontator::Thread.new(commontable: self, commontable_type: "MaintBlueShift")
    
    self.need_help_comment_thread ||= Commontator::Thread.new(commontable: self, commontable_type: "MaintBlueShift")
    
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
  
  def send_alerts_for_fix_by_date_changes
    ["people", "vendor", "parts"].each do |problem|
      send_alert_for_fix_by_date_change(problem)
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
    I18n.t('alerts.maint_blue_shifts.fix_by_date_update', problem: problem,
      property: self.property.code,
      user: @current_user.present? ? @current_user.name : 'unknown',
      original_date: original_date.strftime("%m/%d/%Y"), new_date: new_date.strftime("%m/%d/%Y"),
      blue_shift_url: url_to_maint_blueshift) 
  end

  def url_to_maint_blueshift
    Rails.application.routes.url_helpers.property_maint_blue_shift_url(self.property, self)
  end

  def send_notification_for_created_blueshift
    send_notification_for_blueshift(false)
  end

  def send_notification_for_updated_blueshift
    send_notification_for_blueshift(true)
  end

  def send_notification_for_blueshift(updated)

    blueshift_type = 'Maintenance Blueshift'
    problems = []

    if people_problem
      problems << "`PEOPLE PROBLEM`"
    end
    if vendor_problem
      problems << "`VENDOR PROBLEM`"
    end 
    if parts_problem
      problems << "`PARTS PROBLEM`"
    end 
    if need_help
      problems << "`NEED HELP`"
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

    due_date = latest_fix_by_date()

    if updated
      if archived
        message = "#{mentions}: A *#{blueshift_type}* created on *#{created_on}* by #{user_name} was just `archived` with status `#{archived_status}`. The due date was `#{due_date}`, with #{problems_string} selected." 
      else
        message = "#{mentions}: A *#{blueshift_type}* created on *#{created_on}* by #{user_name} was just `updated` with *#{problems_string}* selected. Due date is currently set to `#{due_date}`. Please review and respond where appropriate. #{url_to_maint_blueshift}"    
      end
    else
      message = "#{mentions}: #{user_name} has `created` a *#{blueshift_type}* with *#{problems_string}* selected. Due date is currently set to `#{due_date}`. Please review and respond where appropriate. #{url_to_maint_blueshift}"    
    end

    unless property.slack_channel.nil?
      channel = Property.blshift_slack_channel(property.slack_channel)
      send_slack_alert(channel, message)
    end

    if !updated && !reviewed
      send_review_needed_message()
    end
  end

  def send_slack_alert(slack_channel, message)
    if slack_channel.include? 'test'
      message.sub! '@', ''
    end 
    send_alert = 
      Alerts::Commands::SendMaintBlueBotSlackMessage.new(message, slack_channel)
    Job.create(send_alert)      
  end

  def slack_mentions(corporate_mention, trs_only)
    if corporate_mention
      # Monica Escobedo
      mentions = "<@UH2SD86H3>"
    else
      mentions = ""
    end

    if !trs_only
      ms_mention = property.maint_super_mention(user)
      if ms_mention != ""
        mentions += " #{ms_mention}"
      end
    end

    trs_mention = property.talent_resource_supervisor_mention(user)
    if trs_mention != ""
      mentions += " #{trs_mention}"
    end

    return mentions
  end

end
