require 'test_helper'
 
class BlueShiftsControllerTest < ActionController::TestCase
  def setup
    @fix_by_date = (Time.now.to_date + 3.days).strftime("%m/%d/%Y")
  end
  
  test "create create a blue_shift" do
    property = properties(:home)

    assert_difference('BlueShift.count') do
      post :create, property_id: property.id,  blue_shift: { 
        people_problem: true, 
        people_problem_fix: 'hire people', 
        people_problem_fix_by: @fix_by_date, 
        product_problem: false, 
        pricing_problem: false, 
        need_help: false, 
        created_on: Time.now.to_date
      }
    end
    
    assert_response :redirect
  end
  
  test "assignes metric for blue_shift" do
    property = properties(:home)
    metric = metrics(:one)

    assert_difference('BlueShift.where(metric_id: metric.id).count') do
      post :create, property_id: property.id,  blue_shift: { 
        people_problem: true, 
        people_problem_fix: 'hire people', 
        people_problem_fix_by: @fix_by_date, 
        product_problem: false, 
        pricing_problem: false, 
        need_help: false, 
        created_on: Time.now.to_date
      }
    end
    
    assert_response :redirect
  end
  
  
  test "assigns property a current blue_shift upon creation" do
    property = properties(:home)
    property.current_blue_shift = nil
    property.save!
  
    post :create, property_id: property.id,  blue_shift: { 
      people_problem: true, 
      people_problem_fix: 'hire people', 
      people_problem_fix_by: @fix_by_date, 
      product_problem: false, 
      pricing_problem: false, 
      need_help: false, 
      created_on: Time.now.to_date
    }

    property.reload
    assert_not_nil property.current_blue_shift
  end
  
  test "prevents creating a blue_shift if user is not assigned the property" do
    property = properties(:home)
    user = users(:homer)
    user.properties = []
    user.properties << properties(:unassigned_property)

    assert_no_difference('BlueShift.count') do
      post :create, property_id: property.id,  blue_shift: { 
        people_problem: true, 
        people_problem_fix: 'hire people', 
        people_problem_fix_by: @fix_by_date, 
        product_problem: false, 
        pricing_problem: false, 
        need_help: false, 
        created_on: Time.now.to_date
      }
    end
  end
  
  test "assign blue_shift_status of pending to property" do
    property = properties(:home)
    assert_difference('Property.where(blue_shift_status: "pending").count') do
      post :create, property_id: property.id,  blue_shift: { 
        people_problem: true, 
        people_problem_fix: 'hire people', 
        people_problem_fix_by: @fix_by_date, 
        product_problem: false, 
        pricing_problem: false, 
        need_help: false, 
        created_on: Time.now.to_date
      }
    end
  end
  
  test "can update people_problem_fix_by" do
    property = properties(:home)
    blue_shift = blue_shifts(:default)

    put :update, property_id: property.id, id: blue_shift.id, blue_shift: { 
      people_problem_fix_by: @fix_by_date, 
    }, format: :json
    
    blue_shift.reload
    assert_equal Date.strptime(@fix_by_date, "%m/%d/%Y"), blue_shift.people_problem_fix_by
    assert_response :success
  end
  
  test "can update product_problem_fix_by" do
    property = properties(:home)
    blue_shift = blue_shifts(:default)

    put :update, property_id: property.id, id: blue_shift.id, blue_shift: { 
      product_problem_fix_by: @fix_by_date, 
    }, format: :json
    
    blue_shift.reload
    assert_equal Date.strptime(@fix_by_date, "%m/%d/%Y"), blue_shift.product_problem_fix_by
  end
  
  test "can update pricing_problem_fix_by" do
    property = properties(:home)
    blue_shift = blue_shifts(:default)

    put :update, property_id: property.id, id: blue_shift.id, blue_shift: { 
      pricing_problem_fix_by: @fix_by_date, 
    }, format: :json
    
    blue_shift.reload
    assert_equal Date.strptime(@fix_by_date, "%m/%d/%Y"), blue_shift.pricing_problem_fix_by
    assert_response :success
  end
  
  test "cannot update people_problem_fix_by if user is a property manager" do
    current_user.t1_role = "property"
    current_user.t2_role = "property_manager"
    current_user.save!
    property = properties(:home)
    blue_shift = blue_shifts(:default)
    original_date = blue_shift.people_problem_fix_by

    put :update, property_id: property.id, id: blue_shift.id, blue_shift: { 
      people_problem_fix_by: @fix_by_date, 
    }, format: :json
    
    blue_shift.reload
    assert_equal original_date, blue_shift.people_problem_fix_by
  end
  
  test "show new form for blue shift" do
    property = properties(:home)
    get :new, property_id: property.id
    assert_response :success
  end
  
  test "assigns metrics_names_causing_blue_shift" do
    property = properties(:home)
    metric = Metric.where(property: property).order("date DESC").first
    metric.occupancy_average_daily = 50
    metric.trending_average_daily = 50
    metric.basis = 100
    metric.save!
    
    get :new, property_id: property.id
    assert_equal ["OCCUPANCY", "TRENDING"], assigns(:metrics_names_causing_blue_shift)
  end
  
  test "can archive a blue shift" do
    property = properties(:home)
    blue_shift = blue_shifts(:default)

    archive = mock()
    BlueShifts::Commands::Archive.expects(:new)
      .with(blue_shift.id, "success", "", nil).returns(archive)
    archive.expects(:perform)

    patch :archive, property_id: property.id, id: blue_shift.id, blue_shift: { 
      archived_status: "success"
    }, format: :json

    assert_response :redirect
  end
  
  test "cannot archive a blue shift if not an admin" do
    current_user.t1_role = "property"
    current_user.t2_role = "property_manager"
    current_user.save!
    property = properties(:home)
    blue_shift = blue_shifts(:default)
    
    BlueShifts::Commands::Archive.expects(:new).never

    patch :archive, property_id: property.id, id: blue_shift.id, blue_shift: { 
      archived_status: "success"
    }, format: :json
    
    assert_response :redirect
  end
  
  test "can delete a blue shift" do
    blue_shift = blue_shifts(:default)
    maint_blue_shift = maint_blue_shifts(:default)
    property = blue_shift.property
    blue_shift.archived = true
    blue_shift.archived_status = "success"
    blue_shift.save!
    maint_blue_shift.archived = true
    maint_blue_shift.archived_status = "success"
    maint_blue_shift.save!

    assert_difference "BlueShift.count", -1 do
      delete :destroy, property_id: property.id, id: blue_shift.id
    end
    
    assert_response :redirect
  end
  
  test "can delete a blue shift if not an admin" do
    current_user.t1_role = "property"
    current_user.t2_role = "property_manager"
    current_user.save!    
    blue_shift = blue_shifts(:default)
    property = blue_shift.property
    blue_shift.archived = true
    blue_shift.archived_status = "success"
    blue_shift.save!

    assert_no_difference "BlueShift.count" do
      delete :destroy, property_id: property.id, id: blue_shift.id
    end
  end
  
end
