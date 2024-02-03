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
require 'test_helper'

class PropertyTest < ActiveSupport::TestCase
  test "require code" do
    property = properties(:home)
    property.code = nil
    property.valid?
    assert property.errors[:code].length > 0, "no validation error"    
  end
  
  # test "require stablue_shift_statustus" do
  #   property = properties(:home)
  #   property.blue_shift_status = nil
  #   property.valid?
    
  #   assert property.errors[:blue_shift_status].length > 0, "no validation error"
  # end
  
  test "require blue_shift_status to be a valid value" do
    property = properties(:home)
    property.blue_shift_status = "bad value"
    property.valid?
    
    assert property.errors[:blue_shift_status].length > 0, "no validation error"
  end

  test "require maint_blue_shift_status to be a valid value" do
    property = properties(:home)
    property.maint_blue_shift_status = "bad value"
    property.valid?
    
    assert property.errors[:maint_blue_shift_status].length > 0, "no validation error"
  end
  
  test "requires a blue_shift if the status is pending" do
    property = properties(:home)
    property.blue_shifts.delete_all
    property.blue_shift_status = "pending"
    property.valid?
    
    assert property.errors[:blue_shifts].length > 0, "no validation error"
  end

  test "requires a maint_blue_shift if the status is pending" do
    property = properties(:home)
    property.maint_blue_shifts.delete_all
    property.maint_blue_shift_status = "pending"
    property.valid?
    
    assert property.errors[:maint_blue_shifts].length > 0, "no validation error"
  end
  
  test "requires a current_blue_shift if the status is pending" do
    property = properties(:home)
    property.current_blue_shift = nil
    property.blue_shift_status = "pending"
    property.valid?
    
    assert property.errors[:current_blue_shift].length > 0, "no validation error"
  end

  test "requires a current_maint_blue_shift if the status is pending" do
    property = properties(:home)
    property.current_maint_blue_shift = nil
    property.maint_blue_shift_status = "pending"
    property.valid?
    
    assert property.errors[:current_maint_blue_shift].length > 0, "no validation error"
  end
  
  test "require no current_blue_shift if the status is required" do
    property = properties(:home)
    property.current_blue_shift = blue_shifts(:default)
    property.blue_shift_status = "required"
    property.valid?
    
    assert property.errors[:current_blue_shift].length > 0, "no validation error"
  end

  test "require no current_maint_blue_shift if the status is required" do
    property = properties(:home)
    property.current_maint_blue_shift = maint_blue_shifts(:default)
    property.maint_blue_shift_status = "required"
    property.valid?
    
    assert property.errors[:current_maint_blue_shift].length > 0, "no validation error"
  end
  
  test "require no current_blue_shift if the status is not_required" do
    property = properties(:home)
    property.current_blue_shift = blue_shifts(:default)
    property.blue_shift_status = "not_required"
    property.valid?
    
    assert property.errors[:current_blue_shift].length > 0, "no validation error"
  end
  
  test "new should default status to not_required" do
    property = Property.new
    property.save
    assert_equal "not_required", property.blue_shift_status
  end
  
  test "require slack channel to include # sign" do
    property = properties(:home)
    property.slack_channel = "somechannel"
    property.valid?
    
    assert property.errors[:slack_channel].length > 0, "no validation error"    
  end
  
  test "allow slack channel to be nil" do
    property = properties(:home)
    property.slack_channel = nil
    property.valid?
    
    assert property.errors[:slack_channel].length == 0, "validation error"     
  end
end
