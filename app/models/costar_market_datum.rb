# == Schema Information
#
# Table name: costar_market_data
#
#  id                           :integer          not null, primary key
#  property_id                  :integer
#  date                         :date
#  submarket_percent_vacant     :decimal(, )
#  average_effective_rent       :decimal(, )
#  studio_effective_rent        :decimal(, )
#  one_bedroom_effective_rent   :decimal(, )
#  two_bedroom_effective_rent   :decimal(, )
#  three_bedroom_effective_rent :decimal(, )
#  four_bedroom_effective_rent  :decimal(, )
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  in_development               :boolean          default(FALSE)
#
class CostarMarketDatum < ActiveRecord::Base
  belongs_to :property
  validates :property, presence: true
  validates :date, presence: true

end
