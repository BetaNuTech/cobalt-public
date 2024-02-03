class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery prepend: true, with: :exception
  before_action :authenticate_user!
    
  before_action :set_javascript_controller_name
  before_action :check_for_dev
  
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end
  
  def set_javascript_controller_name
    @javascript_controller_name = controller_name.camelize + action_name.camelize + 'Controller'
  end

  def check_for_dev
      @title_name = 'Cobalt'
      @dev_app = false
      if Settings.host == 'cobalt-dev.herokuapp.com'
        @title_name = '*** Cobalt DEV ***'
        @dev_app = true
      end
  end

end
