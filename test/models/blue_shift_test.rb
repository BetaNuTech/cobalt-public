# == Schema Information
#
# Table name: blue_shifts
#
#  id                                                  :integer          not null, primary key
#  property_id                                         :integer
#  created_on                                          :date
#  people_problem                                      :boolean
#  people_problem_fix                                  :text
#  people_problem_fix_by                               :date
#  product_problem                                     :boolean
#  product_problem_fix                                 :text
#  product_problem_fix_by                              :date
#  pricing_problem                                     :boolean
#  pricing_problem_fix                                 :text
#  pricing_problem_fix_by                              :date
#  need_help                                           :boolean
#  need_help_with                                      :text
#  created_at                                          :datetime         not null
#  updated_at                                          :datetime         not null
#  user_id                                             :integer
#  comment_thread_id                                   :integer
#  people_problem_comment_thread_id                    :integer
#  product_problem_comment_thread_id                   :integer
#  pricing_problem_comment_thread_id                   :integer
#  need_help_comment_thread_id                         :integer
#  archived                                            :boolean
#  archived_status                                     :string
#  metric_id                                           :integer
#  no_people_problem_reason                            :text
#  no_people_problem_checked                           :boolean
#  archive_edit_user_id                                :integer
#  initial_archived_status                             :string
#  archive_edit_date                                   :date
#  reviewed                                            :boolean          default(FALSE)
#  people_problem_reason_all_office_staff              :boolean          default(FALSE)
#  people_problem_reason_short_staffed                 :boolean          default(FALSE)
#  people_problem_reason_specific_people               :boolean          default(FALSE)
#  people_problem_specific_people                      :text
#  people_problem_details                              :text
#  product_problem_reason_curb_appeal                  :boolean          default(FALSE)
#  product_problem_reason_unit_make_ready              :boolean          default(FALSE)
#  product_problem_reason_maintenance_staff            :boolean          default(FALSE)
#  product_problem_details                             :text
#  product_problem_specific_people                     :text
#  initial_archived_date                               :date
#  people_problem_fix_results                          :text
#  product_problem_fix_results                         :text
#  archived_failure_reasons                            :string
#  need_help_marketing_problem                         :boolean
#  need_help_marketing_problem_marketing_reviewed      :boolean
#  need_help_capital_problem                           :boolean
#  need_help_capital_problem_explained                 :text
#  need_help_capital_problem_asset_management_reviewed :boolean
#  need_help_capital_problem_maintenance_reviewed      :boolean
#  basis_triggered_value                               :decimal(, )
#  trending_average_daily_triggered_value              :decimal(, )
#  physical_occupancy_triggered_value                  :decimal(, )
#  pricing_problem_denied                              :boolean          default(FALSE)
#  pricing_problem_approved                            :boolean          default(FALSE)
#  pricing_problem_approved_cond                       :boolean          default(FALSE)
#  pricing_problem_approved_cond_text                  :text
#
require 'test_helper'

class BlueShiftTest < ActiveSupport::TestCase
  test "require people_problem to be true or false" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem = nil
    blue_shift.valid?

    assert blue_shift.errors[:people_problem].length > 0, "no validation error"
  end
  
  test "require people_problem_fix if people_problem is true" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem = true
    blue_shift.people_problem_fix = nil
    blue_shift.valid?

    assert blue_shift.errors[:people_problem_fix].length > 0, "no validation error"
  end
  
  test "require people_problem_fix_by if people_problem is true" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem = true
    blue_shift.people_problem_fix_by = nil
    blue_shift.valid?

    assert blue_shift.errors[:people_problem_fix_by].length > 0, "no validation error"
  end
  
  test "sets people_problem_comment_thread if people_problem is true" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem = true
    blue_shift.people_problem_comment_thread = nil
    blue_shift.save
    
    assert_not_nil blue_shift.people_problem_comment_thread
  end
  
  test "does not set new people_problem_comment_thread if already exists" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem = true
    blue_shift.people_problem_fix = "whoa"
    blue_shift.save
      
    thread = blue_shift.people_problem_comment_thread 
    
    blue_shift.people_problem_fix = "blah blah"
    blue_shift.save
  
    assert_equal thread, blue_shift.people_problem_comment_thread 
  end
  
  test "require people_problem_fix_by to be on today or after" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem = true
    blue_shift.people_problem_fix = "okay okay"
    blue_shift.people_problem_fix_by = Time.now.to_date - 1.day
    blue_shift.valid?
  
    assert blue_shift.errors[:people_problem_fix_by].length > 0, "no validation error"
  end
  
  test "changing another blue shift attribute does not run people_problem_fix_by to be on today or after validation" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem = true
    blue_shift.people_problem_fix = "okay okay"
    blue_shift.people_problem_fix_by = Time.now.to_date - 1.day
    blue_shift.save!(validate: false)
    
    blue_shift.pricing_problem = true
    blue_shift.pricing_problem_fix = "yep yep"
    blue_shift.pricing_problem_fix_by = Time.now.to_date + 1.day
    
    assert_equal true, blue_shift.valid?
  end
  
  test "require product_problem to be true or false" do
    blue_shift = blue_shifts(:default)
    blue_shift.product_problem = nil
    blue_shift.valid?

    assert blue_shift.errors[:product_problem].length > 0, "no validation error"
  end
  
  test "require product_problem_fix if product_problem is true" do
    blue_shift = blue_shifts(:default)
    blue_shift.product_problem = true
    blue_shift.product_problem_fix = nil
    blue_shift.valid?

    assert blue_shift.errors[:product_problem_fix].length > 0, "no validation error"
  end
  
  test "require product_problem_fix_by if product_problem is true" do
    blue_shift = blue_shifts(:default)
    blue_shift.product_problem = true
    blue_shift.product_problem_fix_by = nil
    blue_shift.valid?

    assert blue_shift.errors[:product_problem_fix_by].length > 0, "no validation error"
  end
  
  test "require product_problem_fix_by to be on today or after" do
    blue_shift = blue_shifts(:default)
    blue_shift.product_problem = true
    blue_shift.product_problem_fix = "okay okay"
    blue_shift.product_problem_fix_by = Time.now.to_date - 1.day
    blue_shift.valid?
  
    assert blue_shift.errors[:product_problem_fix_by].length > 0, "no validation error"
  end
  
  test "sets product_problem_comment_thread if product_problem is true" do
    blue_shift = blue_shifts(:default)
    blue_shift.product_problem = true
    blue_shift.product_problem_comment_thread = nil
    blue_shift.save
    
    assert_not_nil blue_shift.product_problem_comment_thread
  end
  
  test "does not set new product_problem_comment_thread if already exists" do
    blue_shift = blue_shifts(:default)
    blue_shift.product_problem = true
    blue_shift.product_problem_fix = "whoa"
    blue_shift.save
      
    thread = blue_shift.product_problem_comment_thread 
    
    blue_shift.product_problem_fix = "blah blah"
    blue_shift.save
  
    assert_equal thread, blue_shift.product_problem_comment_thread 
  end
  
  test "require pricing_problem to be true or false" do
    blue_shift = blue_shifts(:default)
    blue_shift.pricing_problem = nil
    blue_shift.valid?

    assert blue_shift.errors[:pricing_problem].length > 0, "no validation error"
  end
  
  test "require pricing_problem_fix if pricing_problem is true" do
    blue_shift = blue_shifts(:default)
    blue_shift.pricing_problem = true
    blue_shift.pricing_problem_fix = nil
    blue_shift.valid?

    assert blue_shift.errors[:pricing_problem_fix].length > 0, "no validation error"
  end
  
  # test "require pricing_problem_fix_by if pricing_problem is true" do
  #   blue_shift = blue_shifts(:default)
  #   blue_shift.pricing_problem = true
  #   blue_shift.pricing_problem_fix_by = nil
  #   blue_shift.valid?

  #   assert blue_shift.errors[:pricing_problem_fix_by].length > 0, "no validation error"
  # end
  
  
  test "require pricing_problem_fix_by to be on today or after" do
    blue_shift = blue_shifts(:default)
    blue_shift.pricing_problem = true
    blue_shift.pricing_problem_fix = "okay okay"
    blue_shift.pricing_problem_fix_by = Time.now.to_date - 1.day
    blue_shift.valid?

    assert blue_shift.errors[:pricing_problem_fix_by].length > 0, "no validation error"
  end
  
  test "sets pricing_problem_comment_thread if pricing_problem is true" do
    blue_shift = blue_shifts(:default)
    blue_shift.pricing_problem = true
    blue_shift.pricing_problem_comment_thread = nil
    blue_shift.save
    
    assert_not_nil blue_shift.pricing_problem_comment_thread
  end
  
  test "does not set new pricing_problem_comment_thread if already exists" do
    blue_shift = blue_shifts(:default)
    blue_shift.pricing_problem = true
    blue_shift.pricing_problem_fix = "whoa"
    blue_shift.save
      
    thread = blue_shift.pricing_problem_comment_thread 
    
    blue_shift.pricing_problem_fix = "blah blah"
    blue_shift.save
  
    assert_equal thread, blue_shift.pricing_problem_comment_thread 
  end
  
  test "require need_help to be true or false" do
    blue_shift = blue_shifts(:default)
    blue_shift.need_help = nil
    blue_shift.valid?

    assert blue_shift.errors[:need_help].length > 0, "no validation error"
  end
  
  test "require need_help_with if need_help is true" do
    blue_shift = blue_shifts(:default)
    blue_shift.need_help = true
    blue_shift.need_help_with = nil
    blue_shift.valid?

    assert blue_shift.errors[:need_help_with].length > 0, "no validation error"
  end  
  
  test "require need_help if there no people, product, or pricing problems" do
    blue_shift = blue_shifts(:default)
    blue_shift.need_help = nil
    blue_shift.people_problem = false
    blue_shift.product_problem = false
    blue_shift.pricing_problem = false
    blue_shift.valid?

    assert blue_shift.errors[:need_help].length > 0, "no validation error"
  end
  
  test "require property" do
    blue_shift = blue_shifts(:default)
    blue_shift.property = nil
    blue_shift.valid?
    
    assert blue_shift.errors[:property].length > 0, "no validation error"
  end  
  
  test "require user" do
    blue_shift = blue_shifts(:default)
    blue_shift.user = nil
    blue_shift.valid?
    
    assert blue_shift.errors[:user].length > 0, "no validation error"
  end  
  
  test "require created_on" do
    blue_shift = blue_shifts(:default)
    blue_shift.created_on = nil
    blue_shift.valid?
    
    assert blue_shift.errors[:created_on].length > 0, "no validation error"
  end 
  
  test "require metric" do
    blue_shift = blue_shifts(:default)
    blue_shift.metric = nil
    blue_shift.valid?
    
    assert blue_shift.errors[:metric].length > 0, "no validation error"
  end 
  
  test "get latest fix_by date" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem_fix_by = Date.new(2016, 1, 15)
    blue_shift.product_problem_fix_by = Date.new(2016, 1, 2)
    blue_shift.pricing_problem_fix_by = nil
    
    assert_equal blue_shift.people_problem_fix_by, blue_shift.latest_fix_by_date
  end
  
  test "return nil for latest fix_by date if all dates are nil" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem_fix_by = nil
    blue_shift.product_problem_fix_by = nil
    blue_shift.pricing_problem_fix_by = nil
    
    assert_nil blue_shift.latest_fix_by_date
  end
  
  test "return true for any_fix_date_expired if people fix_by date has expired" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem_fix_by = 1.day.ago
    blue_shift.product_problem_fix_by = 5.days.from_now
    blue_shift.pricing_problem_fix_by = 5.days.from_now
    
    assert_equal true, blue_shift.any_fix_by_date_expired?
  end
  
  test "return true for any_fix_date_expired if product fix_by date has expired" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem_fix_by = 5.day.from_now
    blue_shift.product_problem_fix_by = 1.days.ago
    blue_shift.pricing_problem_fix_by = 5.days.from_now
    
    assert_equal true, blue_shift.any_fix_by_date_expired?
  end
  
  test "return true for any_fix_date_expired if pricing fix_by date has expired" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem_fix_by = 5.days.from_now
    blue_shift.product_problem_fix_by = 5.days.from_now
    blue_shift.pricing_problem_fix_by = 1.days.ago
    
    assert_equal true, blue_shift.any_fix_by_date_expired?
  end
  
  test "return false for any_fix_date_expired if no fix_by date has expired" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem_fix_by = 5.days.from_now
    blue_shift.product_problem_fix_by = 5.days.from_now
    blue_shift.pricing_problem_fix_by = nil
    
    assert_equal false, blue_shift.any_fix_by_date_expired?
  end
  
  test "return true for need_help_with_no_selected_problems" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem = false
    blue_shift.product_problem = false
    blue_shift.pricing_problem = false
    blue_shift.need_help = true
    
    assert_equal true, blue_shift.need_help_with_no_selected_problems?
  end
  
  test "return false for need_help_with_no_selected_problems if one problem selected" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem = false
    blue_shift.product_problem = true
    blue_shift.pricing_problem = false
    blue_shift.need_help = true
    
    assert_equal false, blue_shift.need_help_with_no_selected_problems?
  end
  
  test "return false for need_help_with_no_selected_problems if need_help is false" do
    blue_shift = blue_shifts(:default)
    blue_shift.people_problem = false
    blue_shift.product_problem = false
    blue_shift.pricing_problem = false
    blue_shift.need_help = false
    
    assert_equal false, blue_shift.need_help_with_no_selected_problems?
  end
  
  test "sets need_help_comment_thread if need_help is true" do
    blue_shift = blue_shifts(:default)
    blue_shift.need_help = true
    blue_shift.need_help_comment_thread = nil
    blue_shift.save
    
    assert_not_nil blue_shift.need_help_comment_thread
  end
  
  test "does not set new need_help_comment_thread if already exists" do
    blue_shift = blue_shifts(:default)
    blue_shift.need_help = true
    blue_shift.save
      
    thread = blue_shift.need_help_comment_thread 
    
    blue_shift.need_help_with = "blah blah"
    blue_shift.save
  
    assert_equal thread, blue_shift.need_help_comment_thread 
  end
  
  test "require archived" do
    blue_shift = blue_shifts(:default)
    blue_shift.archived = nil
    blue_shift.valid?
    assert blue_shift.errors[:archived].length > 0, "no validation error"    
  end
  
  test "new should default archived to false" do
    blue_shift = BlueShift.new
    blue_shift.save
    assert_equal false, blue_shift.archived
  end
  
  test "require archived_status if archived" do
    blue_shift = blue_shifts(:default)
    blue_shift.archived = true
    blue_shift.archived_status = nil
    blue_shift.valid?
    assert blue_shift.errors[:archived_status].length > 0, "no validation error"    
  end
  
  test "require archived_status to be success or failure" do
    blue_shift = blue_shifts(:default)
    blue_shift.archived = true
    blue_shift.archived_status = "blah"
    blue_shift.valid?
    assert blue_shift.errors[:archived_status].length > 0, "no validation error"    
  end
  
  test "sends alert when updating people_problem_fix_by" do
    assert_alert_gets_sent_for_fix_by_update("people")
  end
  
  test "does not send alert when updating people_problem_fix_by if old date was nil" do
    assert_alert_gets_sent_for_fix_by_update("people")
  end
  
  test "sends alert when updating product_problem_fix_by" do
    assert_alert_gets_sent_for_fix_by_update("product")
  end
  
  test "does not send alert when updating product_problem_fix_by if old date was nil" do
    assert_alert_gets_sent_for_fix_by_update("product")
  end
  
  test "sends alert when updating pricing_problem_fix_by" do
    assert_alert_gets_sent_for_fix_by_update("pricing")
  end
  
  test "does not send alert when updating pricing_problem_fix_by if old date was nil" do
    assert_alert_gets_sent_for_fix_by_update("pricing")
  end
  
  
  def alert_fix_by_date_message(blue_shift, problem, user, original_date, new_date)
    message = I18n.t('alerts.blue_shifts.fix_by_date_update', problem: problem,
      property: blue_shift.property.code,
      user: user.name,
      original_date: original_date.strftime("%m/%d/%Y"), new_date: new_date.strftime("%m/%d/%Y"),
      blue_shift_url: Rails.application.routes.url_helpers.property_blue_shift_url(blue_shift.property, blue_shift)) 
    
    return message
  end
  
  def assert_alert_gets_sent_for_fix_by_update(problem)
    blue_shift = blue_shifts(:default)
    blue_shift.current_user = users(:homer)
    new_date = 11.days.from_now
    blue_shift.send("#{problem}_problem=", true)
    blue_shift.send("#{problem}_problem_fix=", "a big problem")
    blue_shift.send("#{problem}_problem_fix_by=", 10.days.from_now) 
    blue_shift.save!
    
    message = alert_fix_by_date_message(blue_shift, problem, blue_shift.current_user,
      blue_shift.send("#{problem}_problem_fix_by"), new_date)
    
    send = mock()
    Alerts::Commands::Send.expects(:new).with(message, blue_shift.property.id)
      .returns(send)
    send.expects(:perform)
    
    blue_shift.send("#{problem}_problem_fix_by=", new_date)
    blue_shift.save!    
  end
  
  def assert_alert_does_not_get_sent_for_fix_by_update_if_originally_nil(problem)
    blue_shift = blue_shifts(:default)
    blue_shift.current_user = users(:homer)
    new_date = 11.days.from_now
    blue_shift.send("#{problem}_problem=", false)
    blue_shift.send("#{problem}_problem_fix=", nil)
    blue_shift.send("#{problem}_problem_fix_by=", nil) 
    blue_shift.needs_help = true
    blue_shift.needs_help_with = "something"
    blue_shift.save!
    
    
    message = alert_fix_by_date_message(blue_shift, problem, blue_shift.current_user,
      blue_shift.send("#{problem}_problem_fix_by"), new_date)
    
    Alerts::Commands::Send.expects(:new).with(message, blue_shift.property.id).never
    
    blue_shift.send("#{problem}_problem_fix_by=", new_date)
    blue_shift.save!    
  end

  
end
