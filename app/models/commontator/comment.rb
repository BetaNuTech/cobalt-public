class Commontator::Comment < ActiveRecord::Base
  belongs_to :creator, polymorphic: true
  belongs_to :editor, polymorphic: true, optional: true
  belongs_to :thread, inverse_of: :comments
  belongs_to :parent, optional: true, class_name: name, inverse_of: :children

  has_many :children, class_name: name, foreign_key: :parent_id, inverse_of: :parent

  validates :editor, presence: true, on: :update
  validates :body, presence: true, uniqueness: {
    scope: [ :creator_type, :creator_id, :thread_id, :deleted_at ], message: :double_posted
  }
  validate :parent_is_not_self, :parent_belongs_to_the_same_thread, if: :parent

  after_commit :send_notification_for_updated_comment

  cattr_accessor :is_votable
  self.is_votable = begin
    require 'acts_as_votable'
    acts_as_votable

    true
  rescue LoadError
    false
  end

  def self.is_votable?
    is_votable
  end

  def is_modified?
    !editor.nil?
  end

  def is_latest?
    thread.latest_comment(false) == self
  end

  def get_vote_by(user)
    return nil unless self.class.is_votable? && !user.nil? && user.is_commontator

    # Preloaded with a condition in thread#nested_comments_for
    votes_for.to_a.find { |vote| vote.voter_id == user.id && vote.voter_type == user.class.name }
  end

  def update_cached_votes(vote_scope = nil)
    self.update_column(:cached_votes_up, count_votes_up(true))
    self.update_column(:cached_votes_down, count_votes_down(true))
  end

  def is_deleted?
    !deleted_at.nil?
  end

  def delete_by(user)
    return false if is_deleted?

    self.deleted_at = Time.now
    self.editor = user
    self.save
  end

  def undelete_by(user)
    return false unless is_deleted?

    self.deleted_at = nil
    self.editor = user
    self.save
  end

  def body
    is_deleted? ? I18n.t(
      'commontator.comment.status.deleted_by', deleter_name: Commontator.commontator_name(editor)
    ) : super
  end

  def created_timestamp
    I18n.t 'commontator.comment.status.created_at',
           created_at: I18n.l(created_at, format: :commontator)
  end

  def updated_timestamp
    I18n.t 'commontator.comment.status.updated_at',
           editor_name: Commontator.commontator_name(editor || creator),
           updated_at: I18n.l(updated_at, format: :commontator)
  end

  ##################
  # Access Control #
  ##################

  def can_be_created_by?(user)
    user == creator && !user.nil? && user.is_commontator &&
    !thread.is_closed? && thread.can_be_read_by?(user)
  end

  def can_be_edited_by?(user)
    return true if thread.can_be_edited_by?(user) &&
                   thread.config.moderator_permissions.to_sym == :e

    comment_edit = thread.config.comment_editing.to_sym
    !thread.is_closed? && !is_deleted? && user == creator && (editor.nil? || user == editor) &&
    comment_edit != :n && (is_latest? || comment_edit == :a) && thread.can_be_read_by?(user)
  end

  def can_be_deleted_by?(user)
    mod_perm = thread.config.moderator_permissions.to_sym
    return true if thread.can_be_edited_by?(user) && (mod_perm == :e || mod_perm == :d)

    comment_del = thread.config.comment_deletion.to_sym
    !thread.is_closed? && user == creator && (!is_deleted? || editor == user) &&
    comment_del != :n && (is_latest? || comment_del == :a) && thread.can_be_read_by?(user)
  end

  def can_be_voted_on?
    !thread.is_closed? && !is_deleted? && thread.is_votable? && self.class.is_votable?
  end

  def can_be_voted_on_by?(user)
    !user.nil? && user.is_commontator && user != creator &&
    thread.can_be_read_by?(user) && can_be_voted_on?
  end

  protected

  # These 2 validation messages are not currently translated because end users should never see them
  def parent_is_not_self
    return if parent != self
    errors.add :parent, 'must be a different comment'
    throw :abort
  end

  def parent_belongs_to_the_same_thread
    return if parent.thread_id == thread_id
    errors.add :parent, 'must belong to the same thread'
    throw :abort
  end

  ##################
  # Notifications #
  ##################

  def send_notification_for_updated_comment

    if is_modified?
      created_or_updated = "updated"
      user = editor
    else
      created_or_updated = "added"
      user = creator
    end

    if thread.commontable_type == 'BlueShift'
      blueshift_type = 'Blueshift'
      blueshift = BlueShift.find(thread.commontable_id)
      unless blueshift.nil?
        if thread_id == blueshift.comment_thread_id
          thread_name = 'General'
        elsif thread_id == blueshift.people_problem_comment_thread_id
          thread_name = 'People Problem'
        elsif thread_id == blueshift.product_problem_comment_thread_id
          thread_name = 'Product Problem'
        elsif thread_id == blueshift.pricing_problem_comment_thread_id
          thread_name = 'Pricing Problem ( @algorithm )'
        elsif thread_id == blueshift.need_help_comment_thread_id
          thread_name = 'Need Help'
        end

        property = blueshift.property
      end

    elsif thread.commontable_type == 'MaintBlueShift'
      blueshift_type = 'Maintenance Blueshift'

      blueshift = MaintBlueShift.find(thread.commontable_id)
      unless blueshift.nil?
        if thread_id == blueshift.comment_thread_id
          thread_name = 'General'
        elsif thread_id == blueshift.people_problem_comment_thread_id
          thread_name = 'People Problem'
        elsif thread_id == blueshift.vendor_problem_comment_thread_id
          thread_name = 'Vendor Problem'
        elsif thread_id == blueshift.parts_problem_comment_thread_id
          thread_name = 'Parts Problem'
        elsif thread_id == blueshift.need_help_comment_thread_id
          thread_name = 'Need Help'
        end

        property = blueshift.property
      end
    elsif thread.commontable_type == 'TrmBlueShift'
      blueshift_type = 'TRM Blueshift'

      blueshift = TrmBlueShift.find(thread.commontable_id)
      unless blueshift.nil?
        if thread_id == blueshift.comment_thread_id
          thread_name = 'General'
        elsif thread_id == blueshift.manager_problem_comment_thread_id
          thread_name = 'Manager Problem'
        elsif thread_id == blueshift.market_problem_comment_thread_id
          thread_name = 'Market Problem'
        elsif thread_id == blueshift.marketing_problem_comment_thread_id
          thread_name = 'Marketing Problem'
        elsif thread_id == blueshift.capital_problem_comment_thread_id
          thread_name = 'Capital Problem'
        end

        property = blueshift.property
      end
    end

    if blueshift.nil?
      thread_name = "Unknown"
      property_code = "Unknown"
    end

    if thread_name.nil?
      thread_name = "Unknown"
    end

    mentions = ''

    unless blueshift.nil?
      if blueshift_type == 'Maintenance Blueshift'
        mentions = ms_slack_mentions(user, blueshift, false)
      elsif blueshift_type == 'Blueshift'
        mentions = pm_slack_mentions(user, blueshift, false)
      elsif blueshift_type == 'TRM Blueshift'
        mentions = corp_trm_slack_mentions(user, blueshift)
      end
    end

    mentions += ': '

    if blueshift_type == 'TRM Blueshift'
      user_name = user.slack_corp_username
    else
      user_name = user.slack_username
    end
    if user_name.nil? || user_name == ""
      user_name = "*#{user.first_name} #{user.last_name}*"
    else
      user_name = "<@#{user_name}>"
    end

    # Add Property code, if a TRM Blueshift
    unless blueshift.nil?
      if blueshift_type == 'TRM Blueshift'
        property_code = "*`#{blueshift.property.code}`* -> "
      end
    end

    if is_deleted?
      message = "#{property_code}#{mentions}#{user_name} has `deleted` a comment in the *#{thread_name}* thread for a *#{blueshift_type}*" 
    else
      message = "#{property_code}#{mentions}#{user_name} has *#{created_or_updated}* a comment in the *#{thread_name}* thread for a *#{blueshift_type}*, please review and respond where appropriate.\n\n```#{body}```"   
    end

    unless property.nil?
      if blueshift_type == 'TRM Blueshift'
        corp_channel = TrmBlueShift.trm_blueshift_channel()
        send_corp_slack_alert(corp_channel, message)
      else
        property_channel = property.slack_channel
        unless property_channel.nil?
          channel = Property.blshift_slack_channel(property_channel)
          send_slack_alert(channel, message)
        end
      end
    end
  end

  def send_slack_alert(slack_channel, message)

    # slack_target = "@channel"
    # slack_channel = update_slack_channel(property.slack_channel)

    # message = "A BlueShift is required for #{property.code}. #{slack_target}" 
    # Remove @, if test
    if slack_channel.include? 'test'
      message.sub! '@', ''
    end 
    send_alert = 
      Alerts::Commands::SendBlueShiftSlackMessage.new(message, slack_channel)
    Job.create(send_alert)      
  end

  def send_corp_slack_alert(slack_channel, message)
    if slack_channel.include? 'test'
      message.sub! '@', ''
    end 
    send_alert = 
      Alerts::Commands::SendCorpBlueBotSlackMessage.new(message, slack_channel)
    Job.create(send_alert)      
  end

  def pm_slack_mentions(user, blueshift, corporate_mention)
    if corporate_mention
      # Monica Escobedo
      mentions = "<@UH2SD86H3>"
    else
      mentions = ""
    end

    mentions += blueshift.property.property_manager_mentions(user)

    trm_mention = blueshift.property.talent_resource_manager_mention(user)
    if trm_mention != ""
      mentions += " #{trm_mention}"
    end

    return mentions
  end

  def ms_slack_mentions(user, blueshift, corporate_mention)
    if corporate_mention
      # Monica Escobedo
      mentions = "<@UH2SD86H3>"
    else
      mentions = ""
    end

    ms_mention = blueshift.property.maint_super_mention(user)
    if ms_mention != ""
      mentions += " #{ms_mention}"
    end

    trs_mention = blueshift.property.talent_resource_supervisor_mention(user)
    if trs_mention != ""
      mentions += " #{trs_mention}"
    end

    return mentions
  end

  def corp_trm_slack_mentions(user, blueshift)
    # Monica Escobedo (Corp)
    mentions = "<@UH2BFC2JG>"

    trm_mention = blueshift.property.corp_talent_resource_manager_mention(user)
    if trm_mention != ""
      mentions += " #{trm_mention}"
    end

    return mentions
  end

end
