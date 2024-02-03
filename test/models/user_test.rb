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
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "require t1_role" do
    user = users(:homer)
    user.t1_role = nil
    user.valid?
    assert user.errors[:t1_role].length > 0, "no validation error"    
  end
  
  test "require t1_role to be valid" do
    user = users(:homer)
    user.t1_role = "blah"
    user.valid?
    assert user.errors[:t1_role].length > 0, "no validation error"    
  end
  
  test "require first_name" do
    user = users(:homer)
    user.first_name = nil
    user.valid?
    assert user.errors[:first_name].length > 0, "no validation error"    
  end
  
  test "require last_name" do
    user = users(:homer)
    user.last_name = nil
    user.valid?
    assert user.errors[:last_name].length > 0, "no validation error"    
  end
  
  test "require property manager to have at least one property" do
    user = users(:homer)
    user.t2_role = "property_manager"
    user.properties = []
    user.valid?
    assert user.errors[:properties].length > 0, "no validation error"        
  end

  test "require maint super to have at least one property" do
    user = users(:maint_super)
    user.t2_role = "maint_super"
    user.properties = []
    user.valid?
    assert user.errors[:properties].length > 0, "no validation error"        
  end
  
  test "do not require corporate or admin to have at least one property" do
    user = users(:homer)
    user.t1_role = "corporate"
    user.properties = []
    user.valid?
    assert user.errors[:properties].length == 0, "validation error"        
  end
  
  test "name returns first and last name" do
    user = users(:homer)
    assert_equal "#{user.first_name} #{user.last_name}", user.name
  end
  
  test "require active" do
    user = users(:homer)
    user.active = nil
    user.valid?
    assert user.errors[:active].length > 0, "no validation error"    
  end
  
  test "new should default active to true" do
    user = User.new
    user.save
    assert_equal true, user.active
  end
  
  test "active_for_authentication? return false if active is false" do
    user = users(:homer)
    user.active = false
    assert_equal false, user.active_for_authentication?
  end
  
  test "active_for_authentication? return true if active is true" do
    user = users(:homer)
    user.active = true
    assert_equal true, user.active_for_authentication?
  end
  
  test "inactive_message returns message if user is deactivated" do
    user = users(:homer)
    user.active = false
    assert_equal "User has been deactivated.", user.inactive_message
  end
  
end
