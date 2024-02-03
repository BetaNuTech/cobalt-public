# == Schema Information
#
# Table name: average_rents_bedroom_details
#
#  id                         :integer          not null, primary key
#  property_id                :integer
#  date                       :date
#  num_of_bedrooms            :decimal(, )
#  net_effective_average_rent :decimal(, )
#  market_rent                :decimal(, )
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  new_lease_average_rent     :decimal(, )
#  renewal_lease_average_rent :decimal(, )
#  nom_of_new_leases          :decimal(, )
#  num_of_renewal_leases      :decimal(, )
#
class AverageRentsBedroomDetail < ActiveRecord::Base
  belongs_to :property
  validates :property, presence: true
  validates :date, presence: true
  validates :num_of_bedrooms, presence: true
  validates :net_effective_average_rent, presence: true
  validates :market_rent, presence: true

end
