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
class Property < ActiveRecord::Base
  mount_uploader :image, PropertyImageUploader
  mount_uploader :logo, PropertyLogoUploader

  has_many :blue_shifts
  has_many :maint_blue_shifts
  has_many :trm_blue_shifts
  belongs_to :current_blue_shift, class_name: 'BlueShift', optional: true
  belongs_to :current_trm_blue_shift, class_name: 'TrmBlueShift', optional: true
  belongs_to :current_maint_blue_shift, class_name: 'MaintBlueShift', optional: true
  belongs_to :team, optional: true

  BLUE_SHIFT_STATUSES = ["not_required", "required", "pending"]
  TYPES = ["Property", "Team"]

  validates :blue_shift_status, presence: true, 
    inclusion: { in: BLUE_SHIFT_STATUSES }
  validates :maint_blue_shift_status, presence: true, 
    inclusion: { in: BLUE_SHIFT_STATUSES }
  validates :trm_blue_shift_status, presence: true, 
    inclusion: { in: BLUE_SHIFT_STATUSES }
  
  validates :type, presence: true, inclusion: { in: TYPES }
  validates :code, presence: true
  validates :blue_shifts, presence: true, if: -> { blue_shift_status == 'pending' }
  validates :maint_blue_shifts, presence: true, if: -> { maint_blue_shift_status == 'pending' }
  validates :trm_blue_shifts, presence: true, if: -> { trm_blue_shift_status == 'pending' }
  validates :current_blue_shift, presence: true, 
    if: -> { blue_shift_status == 'pending' }
  validates :current_blue_shift, absence: true, 
    if: -> { blue_shift_status == 'not_required' or blue_shift_status == 'required' }   
  validates :current_maint_blue_shift, presence: true, 
    if: -> { maint_blue_shift_status == 'pending' }
  validates :current_maint_blue_shift, absence: true, 
    if: -> { maint_blue_shift_status == 'not_required' or maint_blue_shift_status == 'required' }
  validates :current_trm_blue_shift, presence: true, 
    if: -> { trm_blue_shift_status == 'pending' }
  validates :current_trm_blue_shift, absence: true, 
    if: -> { trm_blue_shift_status == 'not_required' or trm_blue_shift_status == 'required' }
  validates_format_of :slack_channel, with: /#.+/, allow_blank: true
  # validates_format_of :manager_slack_username, with: /@.+/, allow_blank: true
  validates_format_of :manager_strikes, with: /[0123]/, allow_blank: false
  validates_format_of :state, with: /[A-Z]{2}/, allow_blank: true
  validates_numericality_of :num_of_units

  before_validation :default_values 

  # before_save :reset_manager_strikes, if: :manager_slack_username_changed?

  scope :properties, -> { where.not(type: 'Team') }
  scope :teams, -> { where(type: 'Team') }
  scope :portfolio, -> { where(code: Property.portfolio_code()).first }

  after_create do
    send_new_property_message
  end

  # TEAMS

  def is_team?
    return self.type == 'Team' ? true : false
  end

  def self.all_blacklist_codes
    codes = Property.where(active: false).pluck('code')
    codes.concat(Property.teams.pluck('code'))
    codes.push(Property.portfolio_code())
    return codes
  end

  # def self.inactive_codes
  #   ['cedar', 'evergree', 'oldetown', 'seminole', 'castleto', 'lamont', 'hickview']
  # end

  # def self.team_codes
  #   return ['Derby', 'Lone Star', 'Outback', 'Whiskey']
  # end

  def self.portfolio_code
    return 'Portfolio'
  end

  def get_position
    Property.get_code_position(code, type)
  end

  def self.get_code_position(property_code, property_type)
    case property_code.downcase
    when 'portfolio'
      return 1
    else
      if property_type == 'Team'
        return 2
      end
      return 3
    end
  end
  

  # USERS

  def property_manager_user

    # Look at PMs only at Property level first
    property_managers = User.where(active: true, t1_role: "property", t2_role: "property_manager")
    
    property_managers.each do |user|
      if user.properties.include?(self)
        return user
      end
    end

    # Look at all PMs
    property_managers = User.where(active: true, t2_role: "property_manager")
    
    property_managers.each do |user|
      if user.properties.include?(self)
        return user
      end
    end

    return nil
  end

  # Return ALL users
  def property_manager_users
    property_managers = User.where(active: true, t2_role: "property_manager")
    
    users = []
    property_managers.each do |user|
      if user.properties.include?(self)
        users << user
      end
    end

    return users
  end

  def maint_super_user
    supers = User.where(active: true, t2_role: "maint_super")
    
    supers.each do |user|
      if user.properties.include?(self)
        return user
      end
    end

    return nil
  end

  # Return ALL users
  def maint_super_users
    supers = User.where(active: true, t2_role: "maint_super")
    
    users = []
    supers.each do |user|
      if user.properties.include?(self)
        users << user
      end
    end

    return users
  end

  def team_lead_property_manager_user
    if team_id
      return User.where(active: true, t2_role: "team_lead_property_manager", team_id: team_id).first
    elsif type == 'Team'
      return User.where(active: true, t2_role: "team_lead_property_manager", team_id: self.id).first
    else  
      # TODO: Remove after we have teams again
      return User.where(active: true, email: "cmurphy@bluestone-prop.com").first
    end
    return nil
  end

  # Return ALL users
  def team_lead_property_manager_users
    if team_id
      return User.where(active: true, t2_role: "team_lead_property_manager", team_id: team_id)
    elsif type == 'Team'
      return User.where(active: true, t2_role: "team_lead_property_manager", team_id: self.id)
    end
    return []
  end

  def team_lead_maint_super_user
    if team_id
      return User.where(active: true, t2_role: "team_lead_maint_super", team_id: team_id).first
    elsif type == 'Team'
      return User.where(active: true, t2_role: "team_lead_maint_super", team_id: self.id).first
    end
    return nil
  end

  def team_lead_maint_super_users
    if team_id
      return User.where(active: true, t2_role: "team_lead_maint_super", team_id: team_id)
    elsif type == 'Team'
      return User.where(active: true, t2_role: "team_lead_maint_super", team_id: self.id)
    end
    return []
  end


  # MENTIONS

  def property_manager_mentions(current_user)
    pm_users = property_manager_users()

    if pm_users.empty?
      return "<unset_property_manager>"
    end

    slack_mentions = ""
    pm_users.each do |user|
      if user.slack_username.nil? || user.slack_username == ""
        slack_mentions << " <unset_property_manager>"
      elsif current_user.nil? || current_user != user
        slack_mentions << " <@#{user.slack_username}>"
      end
    end

    return slack_mentions
  end

  def maint_super_mention(current_user)
    maint_super = maint_super_user

    if maint_super.nil?
      return "<unset_maint_super>"
    elsif maint_super.slack_username.nil? || maint_super.slack_username == ""
      return "<unset_maint_super>"
    elsif current_user.nil? || current_user != maint_super
      return "<@#{maint_super.slack_username}>"
    end

    return ""
  end

  def talent_resource_manager_mention(current_user)
    # # Check to see if there is a Team first
    # if type != 'Team'&& team_id.nil?
    #   return ""
    # end

    team_lead = team_lead_property_manager_user()

    if team_lead.nil?
      return "<unset_talent_resource_manager>"
    elsif team_lead.slack_username.nil? || team_lead.slack_username == ""
      return "<unset_talent_resource_manager>"
    elsif current_user.nil? || current_user != team_lead
      return "<@#{team_lead.slack_username}>"
    end

    return ""
  end

  # TODO: Support corporate usernames
  def corp_talent_resource_manager_mention(current_user)
    # # Check to see if there is a Team first
    # if type != 'Team'&& team_id.nil?
    #   return ""
    # end

    team_lead = team_lead_property_manager_user()

    if team_lead.nil?
      return "<unset_talent_resource_manager>"
    elsif team_lead.slack_corp_username.nil? || team_lead.slack_corp_username == ""
      return "<unset_talent_resource_manager>"
    elsif current_user.nil? || current_user != team_lead
      return "<@#{team_lead.slack_corp_username}>"
    end

    return ""
  end

  def talent_resource_supervisor_mention(current_user)
    team_lead = team_lead_maint_super_user

    if team_lead.nil?
      return "<unset_talent_resource_supervisor>"
    elsif team_lead.slack_username.nil? || team_lead.slack_username == ""
      return "<unset_talent_resource_supervisor>"
    elsif current_user.nil? || current_user != team_lead
      return "<@#{team_lead.slack_username}>"
    end

    return ""
  end

  def bluebot_pvt_mention(corporate_mention)
    if corporate_mention
      # Monica Escobedo
      mentions = "<@UH2SD86H3>"
    else
      mentions = ""
    end

    if code.downcase == 'portfolio' || type == 'Team'
      mentions = '@channel'
    else
      mentions += property_manager_mentions(nil)

      trm_mention = talent_resource_manager_mention(nil)
      if trm_mention != ""
        mentions += " #{trm_mention}"
      end
    end

    return mentions
  end

  def bluebot_blshift_mention(corporate_mention)
    if corporate_mention
      # Monica Escobedo
      mentions = "<@UH2SD86H3>"
    else
      mentions = ""
    end

    if code.downcase == 'portfolio' || type == 'Team'
      mentions = '@channel'
    else
      mentions += property_manager_mentions(nil)

      trm_mention = talent_resource_manager_mention(nil)
      if trm_mention != ""
        mentions += " #{trm_mention}"
      end
    end

    return mentions
  end

  def bluebot_trm_blshift_mention(corporate_mention)
    if corporate_mention
      # Monica Escobedo
      mentions = "<@UH2BFC2JG>"
    else
      mentions = ""
    end

    if code.downcase == 'portfolio' || type == 'Team'
      mentions = '@channel'
    else
      trm_mention = corp_talent_resource_manager_mention(nil)
      if trm_mention != ""
        mentions += " #{trm_mention}"
      end
    end

    return mentions
  end

  def maint_bluebot_pvt_mention(corporate_mention)
    if corporate_mention
      # Monica Escobedo
      mentions = "<@UH2SD86H3>"
    else
      mentions = ""
    end

    if code.downcase == 'portfolio' || type == 'Team'
      mentions = '@channel'
    else
      ms_mention = maint_super_mention(nil)
      if ms_mention != ""
        mentions += " #{ms_mention}"
      end

      trs_mention = talent_resource_supervisor_mention(nil)
      if trs_mention != ""
        mentions += " #{trs_mention}"
      end
    end

    return mentions
  end

  def maint_bluebot_blshift_mention(corporate_mention)
    if corporate_mention
      # Monica Escobedo
      mentions = "<@UH2SD86H3>"
    else
      mentions = ""
    end

    if code.downcase == 'portfolio' || type == 'Team'
      mentions = '@channel'
    else
      ms_mention = maint_super_mention(nil)
      if ms_mention != ""
        mentions += " #{ms_mention}"
      end

      trs_mention = talent_resource_supervisor_mention(nil)
      if trs_mention != ""
        mentions += " #{trs_mention}"
      end
    end

    return mentions
  end

  def leasing_mention
    if slack_channel.nil?
      return ''
    end

    mention = slack_channel.dup
    mention.sub! '#', ''        

    mention.sub! 'prop-', ''
    mention.sub! 'test-', ''
    mention = mention + '_leasing'

    if !mention.include? 'test'
      mention = '@' + mention
    end

    return mention
  end

  def bluebot_leasing_mention
    if slack_channel.nil?
      return ''
    end

    mentions = leasing_mention

    mentions += " #{maint_mention}"

    if code.downcase == 'portfolio' || type == 'Team'
      mentions = '@channel'
    else
      mentions += property_manager_mentions(nil)

      trm_mention = talent_resource_manager_mention(nil)
      if trm_mention != ""
        mentions += " #{trm_mention}"
      end
    end

    return mentions
  end

  def maint_mention
    if slack_channel.nil?
      return ''
    end

    mention = slack_channel.dup
    mention.sub! '#', ''        

    mention.sub! 'prop-', ''
    mention.sub! 'test-', ''
    mention = mention + '_maint'

    if !mention.include? 'test'
      mention = '@' + mention
    end

    return mention
  end

  def bluebot_maint_mention(include_ms, include_trs)
    if slack_channel.nil?
      return ''
    end

    mentions = maint_mention

    mentions += " #{leasing_mention}"

    if code.downcase == 'portfolio' || type == 'Team'
      mentions = '@channel'
    else
      if include_ms
        ms_mention = maint_super_mention(nil)
        if ms_mention != ""
          mentions += " #{ms_mention}"
        end
      end

      if include_trs
        trs_mention = talent_resource_supervisor_mention(nil)
        if trs_mention != ""
          mentions += " #{trs_mention}"
        end
      end
    end

    return mentions
  end


  # CHANNELS

  def update_slack_channel
    channel = ''

    if slack_channel.nil?
      return channel
    end

    unless Rails.env.test?
      channel = slack_channel.dup
      if Settings.slack_test_mode == 'enabled'
        channel.sub! 'prop', 'test'
      else
        channel.sub! 'test', 'prop'
      end   
    end

    return channel
  end

  def self.blshift_slack_channel(slack_channel)
    channel = ''

    if slack_channel.nil?
      return channel
    end

    unless Rails.env.test?
      channel = slack_channel.dup
      if Settings.slack_test_mode == 'enabled'
        channel.sub! 'prop', 'test'
        channel.sub! 'blueshift', 'test'
      else
        channel.sub! 'test', 'blueshift'
        channel.sub! 'prop', 'blueshift'
      end   
    end

    # channel name changes, due to character limit
    channel.sub! 'brooklyn-place', 'brooklyn'
    channel.sub! 'eagles-landing', 'eagles'
    channel.sub! 'tuscany-villas', 'tuscany'
    channel.sub! 'vantage-pointe', 'vantagepointe'
    channel.sub! 'villas-cordova', 'villas'
    channel.sub! 'woodland-lakes', 'woodland'

    return channel
  end

  def self.pvt_slack_channel(slack_channel)
    channel = ''

    if slack_channel.nil?
      return channel
    end

    unless Rails.env.test?
      channel = slack_channel.dup
      if Settings.slack_test_mode == 'enabled'
        channel.sub! 'prop', 'test'
        channel.sub! 'pvt', 'test'
      else
        channel.sub! 'test', 'pvt'
        channel.sub! 'prop', 'pvt'
      end   
    end

    return channel
  end

  def slack_channel_for_leasing
    channel = ''

    if slack_channel.nil?
      return channel
    end

    unless Rails.env.test? || slack_channel.nil?
      channel = slack_channel.dup          
      if code.downcase != 'portfolio'
        channel.sub! 'prop', 'leasing'
      end
      
      if Settings.slack_test_mode == 'enabled'
        channel.sub! 'leasing', 'test'
        channel.sub! 'prop', 'test'
      end
    end
  
    # channel name changes, due to character limit
    channel.sub! 'brooklyn-place', 'brooklyn'
    channel.sub! 'eagles-landing', 'eagles'
    channel.sub! 'tuscany-villas', 'tuscany'
    channel.sub! 'vantage-pointe', 'vantage'
    channel.sub! 'villas-cordova', 'villas'
    channel.sub! 'woodland-lakes', 'woodland'
    
    return channel
  end

  def slack_channel_for_hr
    channel = ''

    if slack_channel.nil?
      return channel
    end

    unless Rails.env.test? || slack_channel.nil?
      channel = slack_channel.dup          
      if code.downcase != 'portfolio'
        channel.sub! 'prop', 'hr'
      end
      
      if Settings.slack_test_mode == 'enabled'
        channel.sub! 'hr', 'test'
        channel.sub! 'prop', 'test'
      end
    end
    
    return channel
  end

  def slack_channel_for_marketing
    channel = ''

    if slack_channel.nil?
      return channel
    end

    unless Rails.env.test? || slack_channel.nil?
      channel = slack_channel.dup          
      if code.downcase != 'portfolio'
        channel.sub! 'prop', 'marketing'
      end
      
      if Settings.slack_test_mode == 'enabled'
        channel.sub! 'marketing', 'test'
        channel.sub! 'prop', 'test'
      end
    end
  
    # channel name changes, due to character limit
    channel.sub! 'brooklyn-place', 'brooklyn'
    channel.sub! 'eagles-landing', 'eagles'
    channel.sub! 'ethan-pointe', 'ethan'
    channel.sub! 'hickory-point', 'nashhick'
    channel.sub! 'houston-levee', 'levee'
    channel.sub! 'marble-alley', 'marblealley'
    channel.sub! 'orchard-hills', 'orchard'
    channel.sub! 'peyton-stakes', 'peyton'
    channel.sub! 'tuscany-villas', 'tuscany'
    channel.sub! 'vantage-pointe', 'vantage'
    channel.sub! 'villas-cordova', 'villas'
    channel.sub! 'woodland-lakes', 'woodland'
    channel.sub! 'walnut-ridge', 'walnut'
    channel.sub! 'walden-legacy', 'walden'
    
    return channel
  end

  def slack_channel_for_capital
    channel = ''

    if slack_channel.nil?
      return channel
    end

    unless Rails.env.test? || slack_channel.nil?
      channel = slack_channel.dup          
      if code.downcase != 'portfolio'
        channel.sub! 'prop', 'capital'
      end
      
      if Settings.slack_test_mode == 'enabled'
        channel.sub! 'capital', 'test'
        channel.sub! 'prop', 'test'
      end
    end
  
    # channel name changes, due to character limit
    channel.sub! 'brooklyn-place', 'brooklyn'
    channel.sub! 'eagles-landing', 'eagleslanding'
    channel.sub! 'hickory-point', 'hickorypointe'
    channel.sub! 'tuscany-villas', 'tuscany'
    channel.sub! 'vantage-pointe', 'vantage'
    channel.sub! 'villas-cordova', 'villas'
    channel.sub! 'woodland-lakes', 'woodland'
    
    return channel
  end

  def slack_channel_for_maint
    channel = ''

    if slack_channel.nil?
      return channel
    end

    if code.downcase == 'portfolio'
      return channel
    end

    unless Rails.env.test?
      channel = slack_channel.dup          
      if code.downcase != 'portfolio'
        channel.sub! 'prop', 'maint'
      end   

      if Settings.slack_test_mode == 'enabled'
        channel.sub! 'maint', 'test'
        channel.sub! 'prop', 'test'
      end
    end

    # channel name changes, due to character limit or otherwise
    channel.sub! 'bandon-trails', 'bandon'
    channel.sub! 'ethan-pointe', 'ethan-point'
    
    return channel
  end



  # PROPERTY BLUESHIFTS

  def self.update_property_trm_blue_shift_status(property, date, should_send_messages)
    return if Property.all_blacklist_codes().include?(property.code)
    
    check_trm_blue_shift_requirement = Properties::Commands::CheckTrmBlueShiftRequirement.new(property.id)
    trm_blue_shift_form_needed = check_trm_blue_shift_requirement.perform

    # AutoN archive, if over 3 weeks old, and blueshift still required.
    # Auto archive, if over 1 day past the latest fix by date, and blueshift still required.
    if property.current_trm_blue_shift.present? && (property.current_trm_blue_shift.latest_fix_by_date() < date) && trm_blue_shift_form_needed
      status = "failure"
      failure_reasons = ''
      if property.current_trm_blue_shift.auto_archive_success?
        status = "success"
      end
      # Check for required results, and if required still, send slack message
      missing_manager_problem_results = false
      if property.current_trm_blue_shift.manager_problem && 
        (property.current_trm_blue_shift.manager_problem_results.nil? || property.current_trm_blue_shift.manager_problem_results == '')
        missing_manager_problem_results = true
      end

      if missing_manager_problem_results
        if should_send_messages
          Property.send_missing_trm_blueshift_results_slack_alert(property, date, status, missing_manager_problem_results)
        end
      else
        archive = TrmBlueShifts::Commands::Archive.new(property.current_trm_blue_shift.id, status, nil)
        archive.perform
        property.trm_blue_shift_status = "required"
        property.current_trm_blue_shift = nil
      end
    elsif trm_blue_shift_form_needed and (property.trm_blue_shift_status == "not_required" || property.trm_blue_shift_status.nil?)
      property.trm_blue_shift_status = "required"
      property.current_trm_blue_shift = nil
    elsif !trm_blue_shift_form_needed  
      if property.current_trm_blue_shift.present?
        # Early success, early archive disabled
        # archive = 
        #   TrmBlueShifts::Commands::Archive.new(property.current_trm_blue_shift.id, "success", nil)
        # archive.perform
      else
        reset_trm_blue_shift_requirement = 
          Properties::Commands::ResetTrmBlueShiftRequirement.new(property.id)
        reset_trm_blue_shift_requirement.perform
      end
    end 
    
    if property.slack_channel.present? and trm_blue_shift_form_needed and property.trm_blue_shift_status == "required" and should_send_messages
      Property.send_trm_blueshift_req_slack_alert(property, date)
    end

    # Send VP reviewed requirement, if not archived and not VP reviewed
    if property.current_trm_blue_shift.present? and should_send_messages
      property.current_trm_blue_shift.send_message_if_vp_review_needed()
   end
    
    property.save!
  end

  def self.update_property_blue_shift_status(property, date, should_send_messages)
    return if Property.all_blacklist_codes().include?(property.code)
    
    check_blue_shift_requirement = Properties::Commands::CheckBlueShiftRequirement.new(property.id)
    blue_shift_form_needed = check_blue_shift_requirement.perform

    # AutoN archive, if over 2 weeks old, and blueshift still required.
    # Auto archive, if over 1 day past the latest fix by date, and blueshift still required.
    if property.current_blue_shift.present? && (property.current_blue_shift.latest_fix_by_date() < date) && blue_shift_form_needed == 'required'
      # Blueshift exists, so reset not needed date
      property.last_no_blue_shift_needed = DateTime.now 

      status = "failure"
      failure_reasons = ''
      if property.current_blue_shift.auto_archive_success?
        status = "success"
      else
        failure_reasons = property.current_blue_shift.auto_archive_failure_reasons_for_date(property.current_blue_shift.latest_fix_by_date() + 1.day)
      end
      # Check for required results, and if required still, send slack message
      missing_people_problem_fix_results = false
      if property.current_blue_shift.people_problem && 
        (property.current_blue_shift.people_problem_fix_results.nil? || property.current_blue_shift.people_problem_fix_results == '')
        missing_people_problem_fix_results = true
      end
      missing_product_problem_fix_results = false
      if property.current_blue_shift.product_problem && 
        (property.current_blue_shift.product_problem_fix_results.nil? || property.current_blue_shift.product_problem_fix_results == '')
        missing_product_problem_fix_results = true
      end

      if missing_people_problem_fix_results || missing_product_problem_fix_results
        if should_send_messages
          Property.send_missing_results_slack_alert(property, date, status, missing_people_problem_fix_results, missing_product_problem_fix_results)
        end

      else
        archive = BlueShifts::Commands::Archive.new(property.current_blue_shift.id, status, failure_reasons, nil)
        archive.perform
        property.blue_shift_status = "required"
        property.current_blue_shift = nil
      end
    elsif blue_shift_form_needed == 'required' && (property.blue_shift_status == "not_required" || property.blue_shift_status.nil?)
      property.blue_shift_status = "required"
      property.current_blue_shift = nil
    # Must be nil, not false, to be valid
    elsif blue_shift_form_needed == 'not_required'

      property.last_no_blue_shift_needed = DateTime.now

      if property.current_blue_shift.present?
        archive = 
          BlueShifts::Commands::Archive.new(property.current_blue_shift.id, "success", "", nil)
        archive.perform
      else
        reset_blue_shift_requirement = 
          Properties::Commands::ResetBlueShiftRequirement.new(property.id)
        reset_blue_shift_requirement.perform
      end
    elsif property.current_blue_shift.present? 
      # Blueshift exists, so reset not needed date
      property.last_no_blue_shift_needed = DateTime.now
    end 

    # Add/Update Compliance Issue, if 7+ days needing a blueshift
    if blue_shift_form_needed == 'required' and property.blue_shift_status == "required" and property.last_no_blue_shift_needed.present?
      if Date.today > property.last_no_blue_shift_needed.to_date + 7.days
        issue = "Blueshift Required (over 7 days)"
        compliance_issue = ComplianceIssue.where(date: Date.today, property: property, issue: issue, trm_notify_only: false).first_or_initialize
        compliance_issue.num_of_culprits = 1
        compliance_issue.culprits = 'Blueshift Required Alert'
        compliance_issue.save!
      end
    end
    
    if property.slack_channel.present? and blue_shift_form_needed == 'required' and property.blue_shift_status == "required" and should_send_messages
      Property.send_blueshift_req_slack_alert(property, date)
    end

    # Send TRM reviewed requirement, if not archived and not reviewed
    if property.current_blue_shift.present? && should_send_messages
       property.current_blue_shift.send_message_if_review_needed()
       property.current_blue_shift.send_message_if_need_help_marketing_problem_review_needed(false)
       property.current_blue_shift.send_messages_if_need_help_capital_problem_reviews_needed(false)
    end

    # day_of_the_week = Date.today.strftime("%A")
    # if day_of_the_week == 'Monday'
    #   # Send reviewed requirement, if necessary
    #   if property.current_blue_shift.present? 
    #     property.current_blue_shift.send_message_if_need_help_marketing_problem_review_needed(false)
    #     property.current_blue_shift.send_messages_if_need_help_capital_problem_reviews_needed(false)
    #   end
    # end
    
    property.save!
  end

  def self.update_property_maint_blue_shift_status(property, date, should_send_messages)
    return if Property.all_blacklist_codes().include?(property.code)
    
    check_maint_blue_shift_requirement = Properties::Commands::CheckMaintBlueShiftRequirement.new(property.id)
    maint_blue_shift_form_needed = check_maint_blue_shift_requirement.perform

    # AutoN archive, if over 2 weeks old, and blueshift still required.
    # Auto archive, if over 1 day past the latest fix by date, and blueshift still required.
    if property.current_maint_blue_shift.present? && (property.current_maint_blue_shift.latest_fix_by_date() < date) and 
      maint_blue_shift_form_needed
      archive = 
      MaintBlueShifts::Commands::Archive.new(property.current_maint_blue_shift.id, "failure", nil)
      archive.perform
      property.maint_blue_shift_status = "required"
      property.current_maint_blue_shift = nil
    elsif maint_blue_shift_form_needed and (property.maint_blue_shift_status == "not_required" || property.maint_blue_shift_status.nil?)
      property.maint_blue_shift_status = "required"
      property.current_maint_blue_shift = nil
    elsif !maint_blue_shift_form_needed  
      if property.current_maint_blue_shift.present?
        archive = 
          MaintBlueShifts::Commands::Archive.new(property.current_maint_blue_shift.id, "success", nil)
        archive.perform
      else
        reset_maint_blue_shift_requirement = 
          Properties::Commands::ResetMaintBlueShiftRequirement.new(property.id)
        reset_maint_blue_shift_requirement.perform
      end
    end 
    
    if property.slack_channel.present? and maint_blue_shift_form_needed and property.maint_blue_shift_status == "required" and should_send_messages
      Property.send_maint_blueshift_req_slack_alert(property, date)
    end

    # Send TRS reviewed requirement, if not archived and not reviewed
    if property.current_maint_blue_shift.present? &&
      !property.current_maint_blue_shift.archived &&
      !property.current_maint_blue_shift.reviewed &&
      should_send_messages
      property.current_maint_blue_shift.send_review_needed_message
    end
    
    property.save!
  end

  def update_latest_inspection(created_on = nil)
    if should_update_latest_inspection?

      if self.sparkle_blshift_pm_templ_name.nil?
        @latest_inspection_error_string = "Sparkle Manager Template Name Missing for Property"
        return
      end

      # Request latest, completed inspection before now
      latest_inspection_action = Sparkle::Commands::LatestInspection.new(property: self, template: self.sparkle_blshift_pm_templ_name, created_on: nil)
      data = latest_inspection_action.perform 
      @latest_inspection_data = data
      @latest_inspection_dict = data[:latest_inspection]
      @latest_inspection_property_dict = data[:property_data]
      @latest_inspection_error_string = data[:error]

      if created_on.present?
        @latest_inspection_by_date = created_on
        # Request latest, completed inspection before created_on date
        latest_inspection_action = Sparkle::Commands::LatestInspection.new(property: self, template: self.sparkle_blshift_pm_templ_name, created_on: created_on)
        data = latest_inspection_action.perform 
        @latest_inspection_by_date_dict = data[:latest_inspection]
        @latest_inspection_by_date_error_string = data[:error]
      else
        @latest_inspection_by_date_dict = nil
        @latest_inspection_by_date_error_string = nil
      end

    end
  end

  def should_update_latest_inspection?
    @latest_inspection_data ||= nil
    return @latest_inspection_data.nil?
  end

  def latest_inspection
    return @latest_inspection_dict
  end

  def latest_inspection_property
    puts @latest_inspection_property_dict
    return @latest_inspection_property_dict
  end

  def latest_inspection_alerts
    alert = nil
    complianceAlert = nil
    if @latest_inspection_dict.present?
      if @latest_inspection_dict["creationDate"].present? && @latest_inspection_dict["completionDate"].present?

        # Compliance (Redbot) Alert & Alert: If creation date is greater than 10 days ago 
        creationDate = Time.at(@latest_inspection_dict["creationDate"]).to_date
        completionDate = Time.at(@latest_inspection_dict["completionDate"]).to_date
        if creationDate < Date.today - 10.days
          alert = "Blueshift Product Inspection OVERDUE (Last: #{creationDate}, Completed: #{completionDate})."
          complianceAlert = alert
        end

        # Compliance (Redbot) Alert & Alert: If completion date is greater than 3 past creation date 
        if completionDate > creationDate + 3.days
          if alert.present?
            alert += ' '
          else
            alert = "Over 3-day max duration, please start and complete inspection within 3 days."
          end
          complianceAlert = alert
        end

        # Alert: If Inspection Score < 90%
        if @latest_inspection_dict["score"].present?
          score = @latest_inspection_dict["score"].to_f
          if score < 90
            if alert.present?
              alert += ' '
            else 
              alert = "POOR RECENT INSPECTION RESULTS. DOUBLE CHECK PRODUCT PROBLEM!"
            end
          end
        end

      end
    elsif @latest_inspection_error_string.nil?
      alert = "Blueshift Product Inspection OVERDUE (Last: NA, Completed: NA)."
      complianceAlert = alert
    end

    return { alert: alert, complianceAlert: complianceAlert }
  end

  def latest_inspection_date_alert?
    if @latest_inspection_dict.present?
      if @latest_inspection_dict["creationDate"].present?
        # Compliance (Redbot) Alert & Alert: If creation date is greater than 10 days ago 
        creationDate = Time.at(@latest_inspection_dict["creationDate"]).to_date
        if creationDate < Date.today - 10.days
          return true
        end
      end
    end

    return false
  end

  def latest_inspection_score_alert?
    if @latest_inspection_dict.present?
        # Alert: If Inspection Score < 90%
        if @latest_inspection_dict["score"].present?
          score = @latest_inspection_dict["score"].to_f
          if score < 90
            return true
          end
        end
    end

    return false
  end

  def latest_inspection_property_di_past_due_alert?
    if @latest_inspection_property_dict.present?
        # Alert: If Inspection Score < 90%
        if @latest_inspection_property_dict["numOfOverdueDeficientItems"].present?
          count = @latest_inspection_dict["numOfOverdueDeficientItems"].to_i
          if count > 0
            return true
          end
        end
    end

    return false
  end

  def latest_inspection_property_di_actions_required_alert?
    if @latest_inspection_property_dict.present?
        # Alert: If Inspection Score < 90%
        if @latest_inspection_property_dict["numOfRequiredActionsForDeficientItems"].present?
          count = @latest_inspection_property_dict["numOfRequiredActionsForDeficientItems"].to_i
          if count > 0
            return true
          end
        end
    end

    return false
  end

  def latest_inspection_by_date
    return @latest_inspection_by_date_dict
  end

  def latest_inspection_by_date_alerts
    alert = nil
    complianceAlert = nil
    if @latest_inspection_by_date_dict.present?
      if @latest_inspection_by_date_dict["creationDate"].present? && @latest_inspection_by_date_dict["completionDate"].present?

        # Compliance (Redbot) Alert & Alert: If creation date is greater than 10 days ago 
        creationDate = Time.at(@latest_inspection_by_date_dict["creationDate"]).to_date
        completionDate = Time.at(@latest_inspection_by_date_dict["completionDate"]).to_date
        if creationDate < @latest_inspection_by_date - 10.days
          alert = "Blueshift Product Inspection OVERDUE (Last: #{creationDate}, Completed: #{completionDate})."
          complianceAlert = alert
        end

        # Compliance (Redbot) Alert & Alert: If completion date is greater than 3 past creation date 
        if completionDate > creationDate + 3.days
          if alert.present?
            alert += ' '
          else 
            alert = "Over 3-day max duration, please start and complete inspection within 3 days."
          end
          complianceAlert = alert
        end

        # Alert: If Inspection Score < 90%
        if @latest_inspection_by_date_dict["score"].present?
          score = @latest_inspection_by_date_dict["score"].to_f
          if score < 90
            if alert.present?
              alert += ' '
            else
              alert = "POOR RECENT INSPECTION RESULTS. DOUBLE CHECK PRODUCT PROBLEM!"
            end
          end
        end

      end
    elsif @latest_inspection_by_date_error_string.nil?
      alert = "Blueshift Product Inspection OVERDUE (Last: NA, Completed: NA)."
      complianceAlert = alert
    end

    return { alert: alert, complianceAlert: complianceAlert }
  end

  def latest_inspection_error
    return @latest_inspection_error_string
  end

  def latest_inspection_by_date_error
    return @latest_inspection_by_date_error_string
  end


  def update_bluesky_stats(on_date = nil)
    if should_update_bluesky_stats?

      # Request latest, completed inspection before now
      action = Bluesky::Commands::PropertyStats.new(property: self, on_date: nil)
      data = action.perform 
      @bluesky_data = data
      # @bluesky_stats = data[:stats]
      # @bluesky_error_string = data[:error]

    end
  end

  def should_update_bluesky_stats?
    @bluesky_data ||= nil
    return @bluesky_data.nil?
  end

  def bluesky_data
    return @bluesky_data
  end
  
  private



  # SLACK MESSAGES

  def send_new_property_message
    send_alert = 
      Alerts::Commands::SendCorpYodaBotSlackMessage.new("@channel: To cobalt a new property added: *`#{self.code}`*", 
      "#onboarding-property")
    Job.create(send_alert)
  end

  def self.send_blueshift_req_slack_alert(property, date)
    # only send messages for current date, looking back and forward days, for any server timezone issues
    # only send messages if after yesterday
    if date < Date.today - 1.day
      return
    end

    mention = property.bluebot_blshift_mention(false)

    slack_channel = Property.blshift_slack_channel(property.slack_channel)

    hostname = Settings.application_host
    message = "A BlueShift is required for #{property.code}. #{mention}\n\n#{hostname}" 
    # Remove @, if test
    if slack_channel.include? 'test'
      message.sub! '@', ''
    end 
    send_alert = Alerts::Commands::SendBlueShiftSlackMessage.new(message, slack_channel)
    Job.create(send_alert)      
  end

  def self.send_maint_blueshift_req_slack_alert(property, date)
    # only send messages for current date, looking back and forward days, for any server timezone issues
      # only send messages if after yesterday
    if date < Date.today - 1.day
      return
    end

    mention = property.maint_bluebot_blshift_mention(false)

    slack_channel = Property.blshift_slack_channel(property.slack_channel)

    hostname = Settings.application_host
    message = "A Maintenance BlueShift is required for #{property.code}. #{mention}\n\n#{hostname}" 
    # Remove @, if test
    if slack_channel.include? 'test'
      message.sub! '@', ''
    end 
    send_alert = Alerts::Commands::SendMaintBlueBotSlackMessage.new(message, slack_channel)
    Job.create(send_alert)      
  end

  def self.send_trm_blueshift_req_slack_alert(property, date)
    # only send messages for current date, looking back and forward days, for any server timezone issues
    # only send messages if after yesterday
    if date < Date.today - 1.day
      return
    end

    mention = property.bluebot_trm_blshift_mention(true)

    slack_channel = TrmBlueShift.trm_blueshift_channel()

    hostname = Settings.application_host
    message = "A TRM BlueShift is required for *`#{property.code}`*. #{mention}\n\n#{hostname}" 
    # Remove @, if test
    if slack_channel.include? 'test'
      message.sub! '@', ''
    end 
    send_alert = Alerts::Commands::SendCorpBlueBotSlackMessage.new(message, slack_channel)
    Job.create(send_alert)      
  end

  def self.send_missing_results_slack_alert(property, date, archive_status, missing_people_problem_fix_results, missing_product_problem_fix_results)
    # only send messages for current date, looking back and forward days, for any server timezone issues
    # only send messages if after yesterday
    if date < Date.today - 1.day
      return
    end

    mention = property.bluebot_blshift_mention(false)

    slack_channel = Property.blshift_slack_channel(property.slack_channel)

    if missing_people_problem_fix_results && missing_product_problem_fix_results
      message = "#{mention}: You have a Blueshift that is due to be archived as a *#{archive_status}*. Please explain your *people* and *product* results for #{property.code}.\n\n" 
    elsif missing_people_problem_fix_results
      message = "#{mention}: You have a Blueshift that is due to be archived as a *#{archive_status}*. Please explain your *people* results for #{property.code}.\n\n" 
    elsif missing_product_problem_fix_results
      message = "#{mention}: You have a Blueshift that is due to be archived as a *#{archive_status}*. Please explain your *product* results for #{property.code}.\n\n" 
    end

    hostname = Settings.application_host
    blueshift_url = "#{hostname}/properties/#{property.id}/blue_shifts/#{property.current_blue_shift.id}"
    message += blueshift_url

    # Remove @, if test
    if slack_channel.include? 'test'
      message.sub! '@', ''
    end 
    send_alert = Alerts::Commands::SendBlueShiftSlackMessage.new(message, slack_channel)
    Job.create(send_alert)  
  end

  def self.send_missing_trm_blueshift_results_slack_alert(property, date, archive_status, missing_manager_problem_fix_results)
    # only send messages for current date, looking back and forward days, for any server timezone issues
    # only send messages if after yesterday
    if date < Date.today - 1.day
      return
    end

    mention = property.bluebot_trm_blshift_mention(true)

    slack_channel = TrmBlueShift.trm_blueshift_channel()

    if missing_manager_problem_fix_results
      message = "*`#{property.code}`* -> #{mention}: You have a TRM Blueshift that is due to be archived as a *#{archive_status}*. Please explain your *manager* results.\n\n" 
    end

    hostname = Settings.application_host
    blueshift_url = "#{hostname}/properties/#{property.id}/trm_blue_shifts/#{property.current_trm_blue_shift.id}"
    message += blueshift_url

    # Remove @, if test
    if slack_channel.include? 'test'
      message.sub! '@', ''
    end 
    send_alert = Alerts::Commands::SendCorpBlueBotSlackMessage.new(message, slack_channel)
    Job.create(send_alert)  
  end


  # HELPERS

  def get_new_or_existing_compliance_issue(date, property, issue)
    return ComplianceIssue.where(date: date, property: property, issue: issue, trm_notify_only: false).first_or_initialize
  end

  def default_values
    # if self.new_record?
    self.blue_shift_status ||= "not_required"
    self.trm_blue_shift_status ||= "not_required"
    self.maint_blue_shift_status ||= "not_required"
    self.manager_strikes ||= 0
    self.type ||= 'Property'
    self.num_of_units ||= 0
    if self.new_record?
      self.active ||= true
    end
    # end
    
    return true
  end

  def reset_manager_strikes
    self.manager_strikes = 0
  end

end
