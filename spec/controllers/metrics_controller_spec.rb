require 'rails_helper'

RSpec.describe MetricsController, type: :controller do
  include_context "users"
  render_views

  describe "GET #index" do
    before do
      admin_user
    end

    it "should be successful" do
      sign_in admin_user
      get :index
      expect(response).to be_successful
      expect(assigns(:team_id)).to be_nil
      expect(assigns(:team_codes)).to be_empty
      expect(response).to render_template('index')
    end

  end
end
