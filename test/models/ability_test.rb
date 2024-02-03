require 'test_helper'

class AbilityTest < ActiveSupport::TestCase
  test "an admin can manager a user" do
    user = users(:admin)
    ability = Ability.new(user)
    assert ability.can?(:manage, User)
  end
  
  test "an admin can update a property" do
    user = users(:admin)
    ability = Ability.new(user)
    assert ability.can?(:update, Property)
  end
  
  test "an admin can read a property" do
    user = users(:admin)
    ability = Ability.new(user)
    assert ability.can?(:read, Property)
  end
  
  test "an admin can edit a blue_shift if assigned no properties" do
    user = users(:admin)
    user.properties = []
    blue_shift = blue_shifts(:default)
    ability = Ability.new(user)
    
    assert ability.can?(:edit, blue_shift)
  end
  
  test "an admin can edit a blue_shift if assigned that property" do
    user = users(:admin)
    blue_shift = blue_shifts(:default)
    user.properties = [blue_shift.property]
    ability = Ability.new(user)
    
    assert ability.can?(:edit, blue_shift)
  end
  
  test "an admin cannot edit a blue_shift if assigned a different property property" do
    user = users(:admin)
    blue_shift = blue_shifts(:default)
    user.properties = [properties(:unassigned_property)]
    ability = Ability.new(user)
    
    assert ability.cannot?(:edit, blue_shift)
  end
  
  test "a corporate user can edit a blue_shift if assigned no properties" do
    user = users(:corporate)
    user.properties = []
    blue_shift = blue_shifts(:default)
    ability = Ability.new(user)
    
    assert ability.can?(:edit, blue_shift)
  end
  
  test "a corporate user can edit a blue_shift if assigned that property" do
    user = users(:corporate)
    blue_shift = blue_shifts(:default)
    user.properties = [blue_shift.property]
    ability = Ability.new(user)
    
    assert ability.can?(:edit, blue_shift)
  end
  
  test "a corporate user cannot edit a blue_shift if assigned a different property property" do
    user = users(:corporate)
    blue_shift = blue_shifts(:default)
    user.properties = [properties(:unassigned_property)]
    ability = Ability.new(user)
    
    assert ability.cannot?(:edit, blue_shift)
  end
  
  test "an admin can create a blue_shift if assigned no properties" do
    user = users(:admin)
    user.properties = []
    property = properties(:home)
    ability = Ability.new(user)
    
    assert ability.can?(:create_blue_shift, property)
  end

  test "an admin can create a blue_shift if assigned that property" do
    user = users(:admin)
    property = properties(:home)
    user.properties = [property]
    ability = Ability.new(user)
    
    assert ability.can?(:create_blue_shift, property)
  end

  test "an admin cannot create a blue_shift if assigned a different property property" do
    user = users(:admin)
    property = properties(:home)
    user.properties = [properties(:unassigned_property)]
    ability = Ability.new(user)
    
    assert ability.cannot?(:create_blue_shift, property)
  end

  test "a corporate user can create a blue_shift if assigned no properties" do
    user = users(:corporate)
    user.properties = []
    property = properties(:home)
    ability = Ability.new(user)
    
    assert ability.can?(:create_blue_shift, property)
  end

  test "a corporate user can create a blue_shift if assigned that property" do
    user = users(:corporate)
    property = properties(:home)
    user.properties = [property]
    ability = Ability.new(user)
    
    assert ability.can?(:create_blue_shift, property)
  end

  test "a corporate user cannot create a blue_shift if assigned a different property property" do
    user = users(:corporate)
    property = properties(:home)
    user.properties = [properties(:unassigned_property)]
    ability = Ability.new(user)
    
    assert ability.cannot?(:create_blue_shift, property)
  end
  

  test "a property_manager can create a blue_shift if assigned that property" do
    user = users(:property_manager)
    property = properties(:home)
    user.properties = [property]
    ability = Ability.new(user)
    
    assert ability.can?(:create_blue_shift, property)
  end

  test "a property_manager cannot create a blue_shift if not assigned" do
    user = users(:property_manager)
    property = properties(:home)
    user.properties = [properties(:unassigned_property)]
    ability = Ability.new(user)
    
    assert ability.cannot?(:create_blue_shift, property)
  end
  
  test "a property_manager can update a blue_shifts problems" do
    user = users(:property_manager)
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem = false
    user.properties = [blue_shift.property]
    ability = Ability.new(user)
    
    assert ability.can?(:add_blue_shift_problem, blue_shift, :people_problem)
  end
  
  test "a property_manager cannot update a blue_shifts problems if not assigned that property" do
    user = users(:property_manager)
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem = false
    user.properties = [properties(:unassigned_property)]
    ability = Ability.new(user)
    
    assert ability.cannot?(:add_blue_shift_problem, blue_shift, :people_problem)
  end
  
  test "a corporate user can update a blue_shifts problem" do
    user = users(:corporate)
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem = false
    user.properties = [blue_shift.property]
    ability = Ability.new(user)
    
    assert ability.can?(:add_blue_shift_problem, blue_shift, :people_problem)
  end

  test "an admin can archive a blue_shift" do
    user = users(:admin)
    blue_shift = blue_shifts(:default)
    ability = Ability.new(user)
    assert ability.can?(:archive, blue_shift)
  end
  
  test "a corporate user can archive a blue_shift" do
    user = users(:corporate)
    blue_shift = blue_shifts(:default)
    ability = Ability.new(user)
    assert ability.can?(:archive, blue_shift)
  end
  
  test "an admin cannot archive a blue_shift that is not persisted" do
    user = users(:admin)
    blue_shift = BlueShift.new
    ability = Ability.new(user)
    assert ability.cannot?(:archive, blue_shift)
  end
  
  test "a property manager cannot archive a blue_shift" do
    user = users(:property_manager)
    blue_shift = blue_shifts(:default)
    ability = Ability.new(user)
    assert ability.cannot?(:archive, blue_shift)
  end
  
  test "an admin can delete a blue_shift" do
    user = users(:admin)
    blue_shift = blue_shifts(:default)
    blue_shift.archived = true
    blue_shift.archived_status = "success"
    ability = Ability.new(user)
    assert ability.can?(:delete, blue_shift)
  end
  
  test "an admin cannot delete a blue_shift if not archived" do
    user = users(:admin)
    blue_shift = blue_shifts(:default)
    blue_shift.archived = false
    ability = Ability.new(user)
    assert ability.cannot?(:delete, blue_shift)
  end
  
  test "a property_manager cannot delete a blue_shift" do
    user = users(:property_manager)
    blue_shift = blue_shifts(:default)
    blue_shift.archived = true
    blue_shift.archived_status = "success"
    ability = Ability.new(user)
    assert ability.cannot?(:delete, blue_shift)
  end
  
end
