require 'test_helper'

class PropertiesControllerTest < ActionController::TestCase
  setup do
    @property = properties(:home)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:properties)
  end
  
  test "should redirect if user does not have rights" do
    current_user.t1_role = "property"
    current_user.t2_role = "property_manager"
    current_user.save!
    get :index
    assert_response :redirect
  end

  test "should show property" do
    get :show, id: @property
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @property
    assert_response :success
  end

  test "should update property" do
    patch :update, id: @property, property: { slack_channel: "#test" }
    assert_redirected_to property_path(assigns(:property))
  end
  
  test "should send test message to slack" do
    send_slack = mock()
    Alerts::Commands::SendSlackMessage.expects(:new).returns(send_slack)
    Job.expects(:create).with(send_slack)
    
    post :send_test_message_to_slack, id: @property

    assert_response :success
  end
  
  test "should redirect send test message if user does not have rights" do
    current_user.t1_role = "property"
    current_user.t2_role = "property_manager"
    current_user.save!

    Alerts::Commands::SendSlackMessage.expects(:new).never
    
    post :send_test_message_to_slack, id: @property

    assert_response :redirect
  end

end
