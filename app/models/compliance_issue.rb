# == Schema Information
#
# Table name: compliance_issues
#
#  id              :integer          not null, primary key
#  property_id     :integer
#  date            :date
#  issue           :string
#  num_of_culprits :decimal(, )
#  culprits        :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  trm_notify_only :boolean          default(FALSE)
#
class ComplianceIssue < ActiveRecord::Base
  belongs_to :property
  validates :property, presence: true
  validates :date, presence: true
  validates :issue, presence: true
  
  def inaction_issue_14_days?
    # case issue
    # when "Sec Dep Check Not Issued"
    #   return true
    # else
    #   return false
    # end
    return false
  end

  def inaction_issue_21_days?
    case issue
    when 'PO > 45 Days Not Closed or Invoiced'
      return true
    else
      return false
    end
  end

  def inaction_issue_28_days?
    case issue
    when 'Unit Vacant Over 60 Days'
      return true
    else
      return false
    end
  end

  def inaction_issue_blacklisted?
    case issue
    when 'POOR RECENT INSPECTION RESULTS. DOUBLE CHECK PRODUCT PROBLEM!'
      return true
    when 'MTM > 5% of Your Unit Count'
      return true
    when 'Partial Payments (over $100)'
      return true
    when 'Payment Plan / Promise to Pay Delinquent'
      return true
    when 'Blueshift Required (over 7 days)'
      return true
    else
      return false
    end

    return false
  end

end
