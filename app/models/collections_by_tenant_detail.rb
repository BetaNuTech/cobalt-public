# == Schema Information
#
# Table name: collections_by_tenant_details
#
#  id                      :integer          not null, primary key
#  property_id             :integer
#  date_time               :datetime
#  tenant_code             :string
#  tenant_name             :string
#  unit_code               :string
#  total_charges           :decimal(, )
#  total_owed              :decimal(, )
#  payment_plan            :boolean
#  eviction                :boolean
#  mobile_phone            :string
#  home_phone              :string
#  office_phone            :string
#  email                   :string
#  last_note               :text
#  payment_plan_delinquent :boolean
#  last_note_updated_at    :datetime
#
class CollectionsByTenantDetail < ActiveRecord::Base
  belongs_to :property
  validates :property, presence: true
  validates :date_time, presence: true
  validates :tenant_code, presence: true
  validates :tenant_name, presence: true
  validates :unit_code, presence: true
  validates :total_charges, presence: true
  validates :total_owed, presence: true
  validates :payment_plan, inclusion: { in: [true, false] }
  validates :eviction, inclusion: { in: [true, false] }

end
