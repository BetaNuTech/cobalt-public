# == Schema Information
#
# Table name: incomplete_work_orders
#
#  id                 :integer          not null, primary key
#  property_id        :integer
#  call_date          :date
#  update_date        :date
#  latest_import_date :date
#  unit               :string
#  work_order         :string
#  brief_desc         :text
#  reason_incomplete  :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class IncompleteWorkOrder < ActiveRecord::Base
  belongs_to :property
  validates :property, presence: true
  validates :call_date, presence: true
  validates :latest_import_date, presence: true
  validates :work_order, presence: true

end
