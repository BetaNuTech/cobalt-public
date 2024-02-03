# == Schema Information
#
# Table name: stat_records
#
#  id           :integer          not null, primary key
#  generated_at :date
#  source       :string
#  name         :string
#  url          :string
#  data         :json
#  raw          :text
#  success      :boolean
#  response     :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class StatRecord < ActiveRecord::Base
  validates :source, presence: true
  validates :name, presence: true
  validates :url, presence: true
  validates :generated_at, presence: true
  validates :data, presence: true

  def self.druidProspectStats(date)
    return StatRecord.where("generated_at = ?", date).where(source: 'druid', name: 'prospect_stats', success: true).order("generated_at DESC").first
  end

  def self.druidPropertyProspectStats(date, property_code)
    return StatRecord.where("generated_at = ?", date).where(source: 'druid', name: "#{property_code}_prospect_stats", success: true).order("generated_at DESC").first      
  end

  def druidProspectStatsForProperty(propertyCode)
    propertiesArray = data['Properties']
    if !propertiesArray.nil? && propertiesArray.kind_of?(Array)
      propertiesArray.each do |propertyHash|
        if propertyHash['ID'] == propertyCode
          return propertyHash['Stats']
        end
      end
    end

    return nil
  end

end
