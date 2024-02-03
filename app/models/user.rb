# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  invitation_token       :string
#  invitation_created_at  :datetime
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_id          :integer
#  invited_by_type        :string
#  invitations_count      :integer          default(0)
#  role                   :string
#  first_name             :string
#  last_name              :string
#  slack_username         :string
#  active                 :boolean
#  t1_role                :string
#  t2_role                :string
#  team_id                :integer
#  view_all_properties    :boolean          default(FALSE)
#  slack_corp_username    :string
#  profile_image          :string
#
class User < ActiveRecord::Base
  mount_uploader :profile_image, ProfileImageUploader
  belongs_to :team, :foreign_key => :team_id, optional: true

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable,  :recoverable, :rememberable, :trackable,
    :validatable
  acts_as_commontator
    
  # ROLES = ["corporate", "property_manager", "admin", "maint_super", "corp_property_manager", "corp_maint_super"]

  T1_ROLES = ["admin", "corporate", "property"]
  T2_ROLES = ["NA", "property_manager", "maint_super", "team_lead_property_manager", "team_lead_maint_super"]
  TEAM_LEADS = ["team_lead_property_manager", "team_lead_maint_super"]
  
  has_and_belongs_to_many :properties
  has_many :user_properties, :dependent => :destroy
  
  attr_accessor :password_override
  
  # validates :role, inclusion: { in: ROLES }
  validates :t1_role, inclusion: { in: T1_ROLES }
  validates :t2_role, inclusion: { in: T2_ROLES }, allow_blank: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  # validates :properties, presence: true, if: "role == 'property_manager' || role == 'maint_super'"
  validates :properties, presence: true, if: -> { t2_role == 'property_manager' || t2_role == 'maint_super' }
  # validates :properties, length: { minimum: 1, maximum: 1 }, :allow_blank => true, if: "role == 'property_manager' || role == 'maint_super'|| role == 'corp_property_manager'|| role == 'corp_maint_super'"
  validates :properties, length: { minimum: 1, maximum: 2 }, allow_blank: true, if: -> { t2_role == 'property_manager' || t2_role == 'maint_super' }
  # validates :properties, length: { minimum: 0, maximum: 1 }, :allow_blank => true, if: "role == 'corp_property_manager'|| role == 'corp_maint_super'"
  validates :active, inclusion: { in: [true, false] }
  
  before_validation :default_values 
  
  def password_required?
    return false if @password_override == true
    return invitation_token.present?
  end
  
  def name
    return "#{first_name} #{last_name}"
  end
  
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
  
  def active_for_authentication?
    super and self.active?
  end
  
  def inactive_message
    self.active? ? super : "User has been deactivated."
  end

  def property_names
    names = []
    self.properties.each do |property|
      names.push property.code
    end
    
    return names.join("<br>")
  end

  def is_an_admin_user
    t1_role == 'admin'
  end

  def is_a_corporate_user
    t1_role == 'corporate'
  end

  def is_a_property_user
    t1_role == 'property'
  end

  def is_a_maint_user
    t2_role == 'maint_super' || t2_role == 'team_lead_maint_super'
  end

  def is_a_team_lead
    TEAM_LEADS.include?(t2_role)
  end

  def get_team_id
    if is_a_team_lead
      return team_id
    elsif properties.count > 0
      prop = properties.first
      return prop.team_id
    end
    return nil
  end

  def team_lead_code
    if is_a_team_lead
      return team_id ? team.code : ''
    end
    return ''
  end

  def team_code
    if is_a_team_lead
      return team_id ? team.code : ''
    elsif properties.count > 0
      prop = properties.first
      return prop.team_id ? prop.team.code : ''
    end
    return ''
  end
  
  private
  def default_values
    if self.new_record?
      self.active ||= true
    end
    
    return true
  end
end
