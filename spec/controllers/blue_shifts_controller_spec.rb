require 'rails_helper'

RSpec.describe BlueShiftsController, type: :controller do
  include_context "users"
  include_context "properties"
  include_context "metrics"
  include_context "blue_shifts"
  render_views

  describe "GET NEW Property #blue_shifts, with need_help selected," do
    before do
      admin_user
      default_property
      default_metric
    end

    it "should be successful" do
      sign_in admin_user
      # get "properties/#{property.id}/blue_shifts/new"
      get :new, :property_id => default_property.id, :need_help => true
      expect(response).to be_successful
      # expect(response).to render_template('blue_shifts/new')
    end
  end

  describe "Create and GET Existing Property #blue_shifts valid case 1" do
    before do
      admin_user
      default_property
      default_metric
      blue_shift_valid_case_1
    end

    it "should be successful" do
      # blue_shift = BlueShift.create(:property => default_property, :metric => default_metric, :user => admin_user, :need_help => true)
      sign_in admin_user
      get :show, :property_id => default_property.id, :id => blue_shift_valid_case_1.id 
      expect(response).to be_successful
      # expect(response).to render_template('blue_shifts/show')
    end
  end

  describe "Create and GET Existing Property #blue_shifts valid case 2" do
    before do
      admin_user
      default_property
      blue_shift_valid_case_2
    end

    it "should be successful" do
      sign_in admin_user
      get :show, :property_id => default_property.id, :id => blue_shift_valid_case_2.id 
      expect(response).to be_successful
    end
  end

  describe "Create and GET Existing Property #blue_shifts valid case 3" do
    before do
      admin_user
      default_property
      blue_shift_valid_case_3
    end

    it "should be successful" do
      sign_in admin_user
      get :show, :property_id => default_property.id, :id => blue_shift_valid_case_3.id 
      expect(response).to be_successful
    end
  end

  describe "Create and GET Existing Property #blue_shifts valid case 4" do
    before do
      admin_user
      default_property
      blue_shift_valid_case_4
    end

    it "should be successful" do
      sign_in admin_user
      get :show, :property_id => default_property.id, :id => blue_shift_valid_case_4.id 
      expect(response).to be_successful
    end
  end

  describe "Create and GET Existing Property #blue_shifts valid case 5" do
    before do
      admin_user
      default_property
      blue_shift_valid_case_5
    end

    it "should be successful" do
      sign_in admin_user
      get :show, :property_id => default_property.id, :id => blue_shift_valid_case_5.id 
      expect(response).to be_successful
    end
  end

end
