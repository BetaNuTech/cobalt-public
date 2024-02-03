# == Schema Information
#
# Table name: accounts_payable_compliance_issues
#
#  id              :integer          not null, primary key
#  property_id     :integer
#  date            :date
#  issue           :string
#  num_of_culprits :decimal(, )
#  culprits        :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class AccountsPayableComplianceIssue < ActiveRecord::Base
  belongs_to :property
  validates :property, presence: true
  validates :date, presence: true
  validates :issue, presence: true

end
