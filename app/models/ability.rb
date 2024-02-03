class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.blank?
    
    if user.t1_role == "admin"
      can :manage, User
      can :read, Property
      can :update, Property
      can :read, Team
      can :update, Team
      
      can :delete, BlueShift do |blue_shift|
        blue_shift.archived?
      end

      can :delete, TrmBlueShift do |trm_blue_shift|
        trm_blue_shift.archived?
      end

      can :delete, MaintBlueShift do |blue_shift|
        blue_shift.archived?
      end

      can :archive, BlueShift do |blue_shift|
        blue_shift.persisted?
      end

      can :archive, TrmBlueShift do |trm_blue_shift|
        trm_blue_shift.persisted?
      end

      can :archive, MaintBlueShift do |blue_shift|
        blue_shift.persisted?
      end

      can :edit_archived_status, BlueShift do |blue_shift|
        blue_shift.archived?
      end

      can :edit_archived_status, TrmBlueShift do |trm_blue_shift|
        trm_blue_shift.archived?
      end

      can :edit_archived_status, MaintBlueShift do |blue_shift|
        blue_shift.archived?
      end

      can :edit_reviewed, BlueShift do |blue_shift|
        blue_shift.persisted?
      end

      can :edit_need_help_reviewed, BlueShift do |blue_shift|
        blue_shift.persisted?
      end
      
      can :edit_results, BlueShift do |blue_shift|
        blue_shift.persisted? && !blue_shift.archived?
      end

      can :edit_results, TrmBlueShift do |trm_blue_shift|
        trm_blue_shift.persisted? && !trm_blue_shift.archived?
      end
    end
    
    if user.t1_role == "corporate" or user.t1_role == "admin"
      can :edit, BlueShift do |blue_shift|
        true
      end
      can :edit, TrmBlueShift do |trm_blue_shift|
        true
      end
      can :edit, MaintBlueShift do |blue_shift|
        true
      end

      can :edit_need_help_reviewed, BlueShift do |blue_shift|
        true
      end
      
      can :create_blue_shift, Property do |property|
        true
      end
      can :create_maint_blue_shift, Property do |property|
        true
      end
      can :create_trm_blue_shift, Property do |property|
        true
      end
      
      can :edit_results, BlueShift do |blue_shift|
        blue_shift.persisted? && !blue_shift.archived?
      end
      can :edit_results, TrmBlueShift do |trm_blue_shift|
        trm_blue_shift.persisted? && !trm_blue_shift.archived?
      end

      can :edit_vp_reviewed, TrmBlueShift do |trm_blue_shift|
        trm_blue_shift.persisted?
      end

      can :show_workable_jobs, :all
    end
    
    if user.t2_role == "property_manager"
      can :create_blue_shift, Property do |property|
        user.properties.include?(property)
      end
      can :edit_results, BlueShift do |blue_shift|
        blue_shift.persisted? && !blue_shift.archived? && user.properties.include?(blue_shift.property)
      end
    elsif user.t2_role == "maint_super"
      can :create_maint_blue_shift, Property do |property|
        user.properties.include?(property)
      end
    elsif user.t2_role == "team_lead_property_manager"
      can :create_blue_shift, Property do |property|
        team_lead_team_match(user, property)
      end 
      can :create_trm_blue_shift, Property do |property|
        team_lead_team_match(user, property)
      end
      can :edit_archived_status, BlueShift do |blue_shift|
        blue_shift.archived?
      end
      can :archive, BlueShift do |blue_shift|
        blue_shift.persisted?
      end
      can :edit_reviewed, BlueShift do |blue_shift|
        blue_shift.persisted? && team_lead_team_match(user, blue_shift.property)
      end
      can :edit_results, BlueShift do |blue_shift|
        blue_shift.persisted? && !blue_shift.archived? && team_lead_team_match(user, blue_shift.property)
      end
      can :edit_results, TrmBlueShift do |trm_blue_shift|
        trm_blue_shift.persisted? && !trm_blue_shift.archived? && team_lead_team_match(user, trm_blue_shift.property)
      end
    elsif user.t2_role == "team_lead_maint_super"
      can :create_maint_blue_shift, Property do |property|
        team_lead_team_match(user, property)
      end
      can :edit_archived_status, MaintBlueShift do |blue_shift|
        blue_shift.archived?
      end
      can :archive, MaintBlueShift do |blue_shift|
        blue_shift.persisted?
      end
      can :edit_reviewed, MaintBlueShift do |blue_shift|
        blue_shift.persisted? && team_lead_team_match(user, property)
      end
    end
    
    
    can :add_blue_shift_problem, BlueShift do |blue_shift, problem|
      if (blue_shift.new_record? or blue_shift.send(problem) == false or blue_shift.send("#{problem}_changed?"))
        if user.t2_role == "property_manager" and user.properties.include?(blue_shift.property)
          true
        elsif user.t2_role == "team_lead_property_manager" and team_lead_team_match(user, blue_shift.property)
          true
        elsif (user.t1_role == "corporate" or user.t1_role == "admin")
          true
        else
          false
        end
      else
        false
      end
    end
    can :add_trm_blue_shift_problem, TrmBlueShift do |trm_blue_shift, problem|
      if (trm_blue_shift.new_record? or trm_blue_shift.send(problem) == false or trm_blue_shift.send("#{problem}_changed?"))
        if user.t2_role == "team_lead_property_manager" and team_lead_team_match(user, trm_blue_shift.property)
          true
        elsif (user.t1_role == "corporate" or user.t1_role == "admin")
          true
        else
          false
        end
      else
        false
      end
    end
    can :add_maint_blue_shift_problem, MaintBlueShift do |maint_blue_shift, problem|
      if (maint_blue_shift.new_record? or maint_blue_shift.send(problem) == false or maint_blue_shift.send("#{problem}_changed?"))
        if user.t2_role == "maint_super" and user.properties.include?(maint_blue_shift.property)
          true
        elsif user.t2_role == "team_lead_maint_super" and team_lead_team_match(user, maint_blue_shift.property)
          true
        elsif (user.t1_role == "corporate" or user.t1_role == "admin")
          true
        else
          false
        end
      else
        false
      end
    end
    
  end
  
  private
  def does_admin_corporate_have_rights_property?(user, property)
    if user.properties.length == 0
      true
    else
      user.properties.include?(property) and user.t2_role != "maint_super"
    end    
  end

  def does_admin_corporate_have_maint_rights_property?(user, property)
    if user.properties.length == 0
      true
    else
      user.properties.include?(property) and user.t2_role != "property_manager"
    end    
  end

  def team_lead_team_match(user, property)
    if property.team && user.team && property.team == user.team # property is part of team
      return true
    elsif user.team && property == user.team # property is a team
      return true
    elsif user.email == "cmurphy@bluestone-prop.com"  # TODO: Remove after we have teams again
      return true
    end 

    return false
  end

end

    
    
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user 
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. 
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
