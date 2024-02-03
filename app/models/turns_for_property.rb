# == Schema Information
#
# Table name: turns_for_properties
#
#  id                       :integer          not null, primary key
#  property_id              :integer
#  date                     :date
#  turned_t9d               :decimal(, )
#  total_vnr_9days_ago      :decimal(, )
#  percent_turned_t9d       :decimal(, )
#  total_vnr                :decimal(, )
#  wo_completed_yesterday   :decimal(, )
#  wo_open_over_48hrs       :decimal(, )
#  wo_percent_completed_t30 :decimal(, )
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
class TurnsForProperty < ActiveRecord::Base
  belongs_to :property
  validates :property, presence: true
  validates :date, presence: true

end
