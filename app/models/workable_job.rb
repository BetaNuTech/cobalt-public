# == Schema Information
#
# Table name: workable_jobs
#
#  id                                 :integer          not null, primary key
#  property_id                        :integer
#  shortcode                          :string
#  state                              :string
#  job_created_at                     :datetime
#  title                              :string
#  code                               :string
#  department                         :string
#  url                                :string
#  application_url                    :string
#  last_activity_member_name          :string
#  last_activity_member_datetime      :datetime
#  last_activity_member_action        :string
#  last_activity_member_stage_name    :string
#  last_activity_candidate_datetime   :datetime
#  last_activity_candidate_action     :string
#  last_activity_candidate_stage_name :string
#  last_offer_sent_at                 :datetime
#  hired_at                           :datetime
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  is_duplicate                       :boolean          default(FALSE)
#  is_repost                          :boolean          default(FALSE)
#  original_job_created_at            :datetime
#  offer_accepted_at                  :datetime
#  background_check_requested_at      :datetime
#  background_check_completed_at      :datetime
#  is_void                            :boolean          default(FALSE)
#  is_hired                           :boolean          default(FALSE)
#  hired_candidate_name               :string
#  hired_candidate_first_name         :string
#  hired_candidate_last_name          :string
#  employee_id                        :integer
#  employee_date_in_job               :datetime
#  employee_date_last_worked          :datetime
#  num_of_offers_sent                 :integer
#  employee_updated_at                :datetime
#  can_post                           :boolean          default(TRUE)
#  new_property                       :boolean          default(FALSE)
#  other_num_of_offers_sent           :integer          default(0)
#  employee_first_name_override       :string
#  employee_last_name_override        :string
#  employee_ignore                    :boolean          default(FALSE)
#
class WorkableJob < ActiveRecord::Base
  belongs_to :property
  belongs_to :employee, optional: true
  validates :property, presence: true
  validates :job_created_at, presence: true
  validates :shortcode, presence: true
  validates :state, presence: true
  validates :title, presence: true
  validates :url, presence: true

  def self.to_csv
    attributes = %w{state property_code title job_created original_job_created num_of_offers_sent days_to_fill pending_hire last_bluestone_activity bluestone_activity_alerts is_hired hired_candidate_name is_void}
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |user|
        csv << attributes.map{ |attr| user.send(attr) }
      end
    end
  end

  def job_created
    self.job_created_at.to_date
  end

  def original_job_created
    if self.original_job_created_at.present?
      return self.original_job_created_at.to_date
    end
    return nil
  end

  def last_bluestone_activity
    if self.last_activity_member_datetime.present?
      return self.last_activity_member_datetime.to_date
    end
    return nil
  end

  def property_code
    return self.property.code
  end

  def pending_hire
    if self.hired_at.nil? && self.offer_accepted_at.present? && self.background_check_completed_at.present?
      return true
    end

    return false
  end

  def days_to_fill
    if self.last_offer_sent_at.present? && self.offer_accepted_at.present?
      job_created_at = self.job_created_at
      if self.original_job_created_at.present?
        job_created_at = self.original_job_created_at
      end

      time_to_fill = (self.offer_accepted_at.to_datetime - job_created_at.to_datetime).to_i
      return time_to_fill
    end
    return nil
  end

  def bluestone_activity_alerts
    if self.last_activity_member_datetime.present?
      return alertForNoMemberActivity(datetime: self.last_activity_member_datetime.to_datetime)
    else  
      return alertForNoMemberActivity(datetime: self.job_created_at.to_datetime)
    end

    return nil
  end

  # Copied from WorkableJobsController
  # Only for red alerts (level 2)
  def alertForNoMemberActivity(datetime:)
    days_ago = (DateTime.now - datetime).to_i
    if days_ago < 0
      return nil
    end
    
    case days_ago
    when 0..7
      return nil
    when 8..10
      return nil
    else
      return "#{days_ago} days: No Bluestone Activity"
    end
  end

end
