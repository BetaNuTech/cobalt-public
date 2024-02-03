# == Schema Information
#
# Table name: renewals_unknown_details
#
#  id          :integer          not null, primary key
#  property_id :integer
#  date        :date
#  yardi_code  :string
#  tenant      :string
#  unit        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class RenewalsUnknownDetail < ActiveRecord::Base
  belongs_to :property
  validates :property, presence: true
  validates :date, presence: true
  validates :yardi_code, presence: true
  validates :tenant, presence: true
  validates :unit, presence: true

end
