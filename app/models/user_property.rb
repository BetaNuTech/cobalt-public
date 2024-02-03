# == Schema Information
#
# Table name: user_properties
#
#  id                      :integer          not null, primary key
#  user_id                 :integer
#  property_id             :integer
#  blue_shift_status       :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  maint_blue_shift_status :string
#  trm_blue_shift_status   :string
#
class UserProperty < ActiveRecord::Base
  belongs_to :user
  belongs_to :property
  
  BLUE_SHIFT_STATUSES = ["none", "unviewed", "viewed"]
  
  validates :user, presence: true
  validates :property, presence: true
  validates :blue_shift_status, presence: true, 
    inclusion: { in: BLUE_SHIFT_STATUSES }
  validates :maint_blue_shift_status, presence: true, 
    inclusion: { in: BLUE_SHIFT_STATUSES }
  validates :trm_blue_shift_status, presence: true, 
    inclusion: { in: BLUE_SHIFT_STATUSES }

  before_validation :default_values

  private

  def default_values
    self.blue_shift_status ||= "none"
    self.maint_blue_shift_status ||= "none"
    self.trm_blue_shift_status ||= "none"
    
    return true
  end
end
