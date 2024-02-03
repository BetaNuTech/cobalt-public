# == Schema Information
#
# Table name: user_properties
#
#  id                      :integer          not null, primary key
#  user_id                 :integer
#  property_id             :integer
#  blue_shift_status       :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  maint_blue_shift_status :string
#  trm_blue_shift_status   :string
#
require 'test_helper'

class UserPropertyTest < ActiveSupport::TestCase
  test "require user" do
    up = user_properties(:default)
    up.user = nil
    up.valid?
    assert up.errors[:user].length > 0, "no validation error"    
  end
  
  test "require property" do
    up = user_properties(:default)
    up.property = nil
    up.valid?
    assert up.errors[:property].length > 0, "no validation error"    
  end
  
  # test "require blue_shift_status" do
  #   up = user_properties(:default)
  #   up.blue_shift_status = nil
  #   up.valid?
    
  #   assert up.errors[:blue_shift_status].length > 0, "no validation error"
  # end
  
  test "require blue_shift_status to be a valid value" do
    up = user_properties(:default)
    up.blue_shift_status = "bad value"
    up.valid?
    
    assert up.errors[:blue_shift_status].length > 0, "no validation error"
  end

  test "require maint_blue_shift_status to be a valid value" do
    up = user_properties(:default)
    up.maint_blue_shift_status = "bad value"
    up.valid?
    
    assert up.errors[:maint_blue_shift_status].length > 0, "no validation error"
  end
  
end
