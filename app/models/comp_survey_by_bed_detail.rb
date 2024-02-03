# == Schema Information
#
# Table name: comp_survey_by_bed_details
#
#  id                     :integer          not null, primary key
#  property_id            :integer
#  date                   :date
#  num_of_bedrooms        :decimal(, )
#  our_market_rent        :decimal(, )
#  comp_market_rent       :decimal(, )
#  our_occupancy          :decimal(, )
#  comp_occupancy         :decimal(, )
#  days_since_last_survey :decimal(, )
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  survey_date            :date
#
class CompSurveyByBedDetail < ActiveRecord::Base
  belongs_to :property
  validates :property, presence: true
  validates :date, presence: true
  validates :survey_date, presence: true
  validates :num_of_bedrooms, presence: true
  validates :our_market_rent, presence: true
  validates :comp_market_rent, presence: true
  validates :our_occupancy, presence: true
  validates :comp_occupancy, presence: true
  validates :days_since_last_survey, presence: true

end
