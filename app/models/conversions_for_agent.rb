# == Schema Information
#
# Table name: conversions_for_agents
#
#  id                     :integer          not null, primary key
#  property_id            :integer
#  date                   :date
#  agent                  :string
#  prospects_10days       :decimal(, )
#  prospects_30days       :decimal(, )
#  prospects_365days      :decimal(, )
#  conversion_10days      :decimal(, )
#  conversion_30days      :decimal(, )
#  conversion_365days     :decimal(, )
#  close_10days           :decimal(, )
#  close_30days           :decimal(, )
#  close_365days          :decimal(, )
#  decline_30days         :decimal(, )
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  prospects_180days      :decimal(, )
#  conversion_180days     :decimal(, )
#  close_180days          :decimal(, )
#  is_property_data       :boolean
#  units                  :integer
#  renewal_30days         :decimal(, )
#  renewal_180days        :decimal(, )
#  renewal_365days        :decimal(, )
#  shows_30days           :decimal(, )
#  shows_180days          :decimal(, )
#  shows_365days          :decimal(, )
#  submits_30days         :decimal(, )
#  submits_180days        :decimal(, )
#  submits_365days        :decimal(, )
#  declines_30days        :decimal(, )
#  declines_180days       :decimal(, )
#  declines_365days       :decimal(, )
#  decline_180days        :decimal(, )
#  decline_365days        :decimal(, )
#  leases_30days          :decimal(, )
#  leases_180days         :decimal(, )
#  leases_365days         :decimal(, )
#  num_of_leads_needed    :decimal(, )
#  druid_prospects_30days :decimal(, )
#
class ConversionsForAgent < ActiveRecord::Base
  belongs_to :property
  validates :property, presence: true
  validates :date, presence: true
  validates :agent, presence: true

  def conversion_30days_level
    return level(conversion_30days)
  end

  def conversion_365days_level
    return level(conversion_365days)
  end

  def close_30days_level
    return level(close_30days)
  end

  def close_365days_level
    return level(close_365days)
  end

  def conversion_10days_level
    return level(conversion_10days)
  end

  def close_10days_level
    return level(close_10days)
  end

  def conversion_180days_level
    return level(conversion_180days)
  end

  def close_180days_level
    return level(close_180days)
  end

  def property_metrics
    if !is_property_data
      return {}
    end

    # renewals (imported as percentages already)
    if    renewal_30days > 0 && renewal_180days > 0 && renewal_365days > 0
      avg_renewal = (renewal_30days + renewal_180days + renewal_365days) / 3.0 / 100.0 # Decimal form of avg. ratios
    elsif renewal_180days > 0 && renewal_365days > 0
      avg_renewal = (renewal_180days + renewal_365days) / 2.0 / 100.0 # Decimal form of avg. ratios
    else
      avg_renewal = renewal_365days / 100.0 # Decimal form of avg. ratios
    end 

    # declines / applies (calculated on import as percentages)
    if    decline_30days > 0 && decline_180days > 0 && decline_365days > 0
      avg_decline = (decline_30days + decline_180days + decline_365days) / 3.0 / 100.0 # Decimal form of avg. ratios
    elsif decline_180days > 0 && decline_365days > 0
      avg_decline = (decline_180days + decline_365days) / 2.0 / 100.0 # Decimal form of avg. ratios
    else
      avg_decline = decline_365days / 100.0 # Decimal form of avg. ratios
    end 

    # shows / prospects (calculated on import as percentages)
    if    conversion_30days > 0 && conversion_180days > 0 && conversion_365days > 0
      avg_conversion = (conversion_30days + conversion_180days + conversion_365days) / 3.0 / 100.0 # Decimal form of avg. ratios
    elsif conversion_180days > 0 && conversion_365days > 0
      avg_conversion = (conversion_180days + conversion_365days) / 2.0 / 100.0 # Decimal form of avg. ratios
    else
      avg_conversion = conversion_365days / 100.0 # Decimal form of avg. ratios
    end 

    # applies / shows (calculated on import as percentages)
    if    close_30days > 0 && close_180days > 0 && close_365days > 0
      avg_closing = (close_30days + close_180days + close_365days) / 3.0 / 100.0 # Decimal form of avg. ratios
    elsif close_180days > 0 && close_365days > 0
      avg_closing = (close_180days + close_365days) / 2.0 / 100.0 # Decimal form of avg. ratios
    else
      avg_closing = close_365days / 100.0 # Decimal form of avg. ratios
    end 

    num_of_annual_moveouts = units * (1.0 - avg_renewal)
    if (1.0 - avg_decline) != 0
      num_of_annual_submits_needed = num_of_annual_moveouts / (1.0 - avg_decline)
    else
      num_of_annual_submits_needed = 0        
    end
    if avg_closing != 0
      num_of_showings_needed = num_of_annual_submits_needed.to_f / avg_closing.to_f
      num_of_showings_needed = num_of_showings_needed.to_i
    else
      num_of_showings_needed = 0       
    end
    if avg_conversion != 0
      num_of_leads_needed = num_of_showings_needed / avg_conversion / 12.0   
    else
      num_of_leads_needed = 0       
    end
    if prospects_30days >= num_of_leads_needed
      alert = "enough leads"
    else
      alert = "not enough leads"
    end
    if conversion_30days * close_30days < 14
      alert += ", low conversion/closing combo"
    end
    if renewal_30days < 40
      alert += ", renewal problem"
    end
    if (1.0 - avg_decline) != 0
      ideal_leads = units * (1.0 - 0.5) / (1.0 - avg_decline) / 0.4 / 0.4 / 12.0 
    else
      ideal_leads = 0       
    end
    if (1.0 - avg_decline) != 0
      blueshift_leads = units * (1.0 - avg_renewal) / (1.0 - avg_decline) / 0.4 / 0.4 / 12.0  
    else
      blueshift_leads = 0       
    end

    {
      :avg_renewal => avg_renewal,
      :avg_decline => avg_decline,
      :avg_conversion => avg_conversion,
      :avg_closing => avg_closing,
      :num_of_annual_moveouts => num_of_annual_moveouts,
      :num_of_annual_submits_needed => num_of_annual_submits_needed,
      :num_of_showings_needed => num_of_showings_needed,
      :num_of_leads_needed => num_of_leads_needed,
      :alert => alert,
      :ideal_leads => ideal_leads,
      :blueshift_leads => blueshift_leads      
    }
  end

  private

  def level(percent_data)
    unless percent_data.nil?
      return 1 if percent_data > 40
      return 2 if percent_data > 39
      return 3 if percent_data >= 30
      return 6 if percent_data < 30
    end
    return nil
  end

end
