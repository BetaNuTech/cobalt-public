# == Schema Information
#
# Table name: sales_for_agents
#
#  id                  :integer          not null, primary key
#  property_id         :integer
#  date                :date
#  agent               :string
#  sales               :integer
#  goal                :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  star_received       :boolean
#  sales_prior_month   :integer
#  super_star_goal     :integer
#  super_star_received :boolean          default(FALSE)
#  missed_goal         :boolean          default(FALSE)
#  goal_for_slack      :integer
#  agent_email         :string
#
class SalesForAgent < ActiveRecord::Base
  belongs_to :property
  validates :property, presence: true
  validates :date, presence: true
  validates :agent, presence: true

  def self.calc_percentage(numerator, denominator) 
    if denominator <= 0 
        percentage = numerator.to_f / 1.0 * 100.0
    else # denominator > 0
      percentage = numerator.to_f / denominator.to_f * 100.0
    end

    return percentage
  end

end
