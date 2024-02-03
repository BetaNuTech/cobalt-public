# == Schema Information
#
# Table name: properties
#
#  id                            :integer          not null, primary key
#  code                          :string
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  blue_shift_status             :string
#  current_blue_shift_id         :integer
#  slack_channel                 :string
#  full_name                     :string
#  manager_strikes               :integer          default(0), not null
#  current_maint_blue_shift_id   :integer
#  maint_blue_shift_status       :string
#  team_id                       :integer
#  active                        :boolean
#  type                          :string
#  city                          :string
#  state                         :string
#  current_trm_blue_shift_id     :integer
#  trm_blue_shift_status         :string
#  sparkle_blshift_pm_templ_name :string
#  logo                          :string
#  image                         :string
#  num_of_units                  :integer
#  last_no_blue_shift_needed     :datetime
#
class Team < Property
  has_many :properties

  before_validation :team_default_values 

  def lead_project_manager
    User.where(active: true).where(t2_role: 'team_lead_property_manager').where(team_id: self.id).first
  end

  def lead_maint_super
    User.where(active: true).where(t2_role: 'team_lead_maint_super').where(team_id: self.id).first
  end

  def property_names
    names = []
    properties = Property.where(active: true, team: self).order(:code)
    properties.each do |property|
      names.push property.code
    end
    
    return names.join("<br>")
  end

  private

  def team_default_values
    self.type ||= 'Team'
    # end
    
    return true
  end
  
end
