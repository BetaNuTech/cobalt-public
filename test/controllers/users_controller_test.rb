require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:homer)
  end
  
  test "should redirect if user does not have rights" do
    current_user.t1_role = "property"
    current_user.t2_role = "property_manager"
    current_user.save!
    get :index
    assert_response :redirect
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post :create, user: { email: "newemail@exmaple.com", t1_role: @user.t1_role, t2_role: @user.t2_role,
        first_name: "first-name", last_name: "last-name" }
    end

    assert_redirected_to user_path(assigns(:user))
  end

  test "should show user" do
    get :show, id: @user
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @user
    assert_response :success
  end

  test "should update user" do
    patch :update, id: @user, user: { email: @user.email, t1_role: @user.t1_role, t2_role: @user.t2_role }
    assert_redirected_to user_path(assigns(:user))
  end
  
  test "should update user even if invitation has been sent" do
    @user.invite!
    patch :update, id: @user, user: { email: @user.email, t1_role: @user.t1_role, t2_role: @user.t2_role }
    assert_redirected_to user_path(assigns(:user))
  end
  
  
  test "should reset password" do
    original_password = @user.encrypted_password
    patch :reset_password, id: @user
    
    @user.reload
    assert_not_equal original_password, @user.encrypted_password
    assert_redirected_to edit_user_path(@user)
  end
  
  test "should send password reset instructions when reseting password" do  
    User.any_instance.expects(:send_reset_password_instructions)
    patch :reset_password, id: @user
  end

  # test "should destroy user" do
  #   assert_difference('User.count', -1) do
  #     delete :destroy, id: @user
  #   end
  # 
  #   assert_redirected_to users_path
  # end
end
