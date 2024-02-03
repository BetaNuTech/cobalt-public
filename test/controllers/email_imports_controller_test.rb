require 'test_helper'

class EmailImportsControllerTest < ActionController::TestCase
  def setup
    login_with_basic_auth
  end
  
  test "create should call import command" do
    command = mock()
    Metrics::Commands::ImportExcelSpreadsheet.expects(:new).returns(command)
    command.expects(:perform)
    
    # file = fixture_file_upload("files/daily_report.xlsx")
    post :create, attachments: { '0' => { 'url' => 'files/daily_report.xlsx' } }
    assert_response :success
  end
  
  def login_with_basic_auth
    request.env['HTTP_AUTHORIZATION'] = 
      ActionController::HttpAuthentication::Basic
      .encode_credentials(Settings.basic_auth_username, Settings.basic_auth_password)
  end  
end