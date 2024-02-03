# == Schema Information
#
# Table name: collections_details
#
#  id                           :integer          not null, primary key
#  property_id                  :integer
#  date_time                    :datetime
#  num_of_units                 :decimal(, )
#  occupancy                    :decimal(, )
#  total_charges                :decimal(, )
#  total_paid                   :decimal(, )
#  total_payment_plan           :decimal(, )
#  total_evictions_owed         :decimal(, )
#  num_of_unknown               :decimal(, )
#  num_of_payment_plan          :decimal(, )
#  num_of_paid_in_full          :decimal(, )
#  num_of_evictions             :decimal(, )
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  paid_full_color_code         :decimal(, )
#  paid_full_with_pp_color_code :decimal(, )
#  avg_daily_occ_adj            :decimal(, )
#  avg_daily_trend_2mo_adj      :decimal(, )
#  past_due_rents               :decimal(, )
#  covid_adjusted_rents         :decimal(, )
#
class CollectionsDetail < ActiveRecord::Base
  belongs_to :property
  validates :property, presence: true
  validates :date_time, presence: true
  validates :num_of_units, presence: true
  validates :occupancy, presence: true
  validates :total_charges, presence: true
  validates :total_paid, presence: true
  validates :total_payment_plan, presence: true
  validates :total_evictions_owed, presence: true
  validates :num_of_unknown, presence: true
  validates :num_of_payment_plan, presence: true
  validates :num_of_paid_in_full, presence: true
  validates :num_of_evictions, presence: true
  validates :paid_full_color_code, presence: true
  validates :paid_full_with_pp_color_code, presence: true

end
