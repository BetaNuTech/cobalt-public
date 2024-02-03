ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require "minitest/reporters"
require 'mocha/mini_test'
Minitest::Reporters.use!

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end



class ActionController::TestCase
  include Devise::Test::ControllerHelpers
  
  @user = nil
  
  setup :login
  
  def login 
    @user = users(:homer)

    session[:user_id] = @user.id 
    
    @request.env["devise.mapping"] = Devise.mappings[:user]
    # user.confirm! # or set a confirmed_at inside the factory. Only necessary if you are using the confirmable module
    sign_in @user 
  end
  
  def current_user
    @user
  end 
  
end
