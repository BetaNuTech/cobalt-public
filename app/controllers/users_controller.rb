class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :set_javascript_controller_name
  load_and_authorize_resource

  # GET /users
  # GET /users.json
  def index
    @sort = params[:sort]
    @users = User.order("active DESC, first_name ASC, last_name ASC")                    
    
    if @sort == 'properties'
      @users = User.where(:active => TRUE).where.not('t1_role=?', 'admin').sort_by { |user| user.property_names }
    elsif @sort == 'role'
      @users = User.where(:active => TRUE).order("t1_role ASC, t2_role ASC, first_name ASC, last_name ASC")
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.invite!(user_params)

    respond_to do |format|
      if @user.errors.empty?
        format.html { redirect_to @user, notice: 'User was successfully invited.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      @user.password_override = true
      puts user_params
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # # DELETE /users/1
  # # DELETE /users/1.json
  # def destroy
  #   @user.destroy
  #   respond_to do |format|
  #     format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
  #     format.json { head :no_content }
  #   end
  # end


  def reset_password
    @user = User.find(params[:id])
    temporary_password = SecureRandom.hex
    @user.reset_password(temporary_password, temporary_password)
    @user.send_reset_password_instructions
    
    redirect_to edit_user_path(@user), notice: 'Password reset instructions sent to the user.'
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:email, :first_name, :last_name,
        :active,
        :t1_role, :t2_role,
        :team_id,
        :profile_image,
        :slack_username,
        :slack_corp_username, {:property_ids => []})
    end
    
    def set_javascript_controller_name
      @javascript_controller_name = controller_name.camelize + 'Controller'
    end
end
