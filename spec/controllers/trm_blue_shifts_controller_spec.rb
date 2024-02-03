require 'rails_helper'

RSpec.describe TrmBlueShiftsController, type: :controller do
  include_context "users"
  include_context "properties"
  include_context "metrics"
  include_context "trm_blue_shifts"
  render_views

  describe "GET NEW Property #trm_blue_shifts" do
    before do
      admin_user
      default_property
      default_metric
    end

    it "should be successful" do
      sign_in admin_user
      # get "properties/#{property.id}/trm_blue_shifts/new"
      get :new, :property_id => default_property.id
      expect(response).to be_successful
      # expect(response).to render_template('blue_shifts/new')
    end
  end

  describe "Create and GET Existing Property #trm_blue_shifts valid case 1" do
    before do
      admin_user
      default_property
      default_metric
      trm_blue_shift_valid_case_1
    end

    it "should be successful" do
      sign_in admin_user
      get :show, :property_id => default_property.id, :id => trm_blue_shift_valid_case_1.id 
      expect(response).to be_successful
    end
  end

  describe "Create and GET Existing Property #trm_blue_shifts valid case 2" do
    before do
      admin_user
      default_property
      trm_blue_shift_valid_case_2
    end

    it "should be successful" do
      sign_in admin_user
      get :show, :property_id => default_property.id, :id => trm_blue_shift_valid_case_2.id 
      expect(response).to be_successful
    end
  end

  describe "Create and GET Existing Property #trm_blue_shifts valid case 3" do
    before do
      admin_user
      default_property
      trm_blue_shift_valid_case_3
    end

    it "should be successful" do
      sign_in admin_user
      get :show, :property_id => default_property.id, :id => trm_blue_shift_valid_case_3.id 
      expect(response).to be_successful
    end
  end

  describe "Create and GET Existing Property #trm_blue_shifts valid case 4" do
    before do
      admin_user
      default_property
      trm_blue_shift_valid_case_4
    end

    it "should be successful" do
      sign_in admin_user
      get :show, :property_id => default_property.id, :id => trm_blue_shift_valid_case_4.id 
      expect(response).to be_successful
    end
  end


end
