# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_04_20_001635) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts_payable_compliance_issues", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.date "date"
    t.string "issue"
    t.decimal "num_of_culprits"
    t.text "culprits"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["property_id"], name: "index_accounts_payable_compliance_issues_on_property_id"
  end

  create_table "audits", id: :serial, force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at", precision: nil
    t.index ["associated_id", "associated_type"], name: "associated_index"
    t.index ["auditable_id", "auditable_type"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "average_rents_bedroom_details", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.date "date"
    t.decimal "num_of_bedrooms"
    t.decimal "net_effective_average_rent"
    t.decimal "market_rent"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "new_lease_average_rent"
    t.decimal "renewal_lease_average_rent"
    t.decimal "nom_of_new_leases"
    t.decimal "num_of_renewal_leases"
    t.index ["date"], name: "index_average_rents_bedroom_details_on_date"
    t.index ["num_of_bedrooms"], name: "index_average_rents_bedroom_details_on_num_of_bedrooms"
    t.index ["property_id"], name: "index_average_rents_bedroom_details_on_property_id"
  end

  create_table "blue_shifts", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.date "created_on"
    t.boolean "people_problem"
    t.text "people_problem_fix"
    t.date "people_problem_fix_by"
    t.boolean "product_problem"
    t.text "product_problem_fix"
    t.date "product_problem_fix_by"
    t.boolean "pricing_problem"
    t.text "pricing_problem_fix"
    t.date "pricing_problem_fix_by"
    t.boolean "need_help"
    t.text "need_help_with"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.integer "comment_thread_id"
    t.integer "people_problem_comment_thread_id"
    t.integer "product_problem_comment_thread_id"
    t.integer "pricing_problem_comment_thread_id"
    t.integer "need_help_comment_thread_id"
    t.boolean "archived"
    t.string "archived_status"
    t.integer "metric_id"
    t.text "no_people_problem_reason"
    t.boolean "no_people_problem_checked"
    t.integer "archive_edit_user_id"
    t.string "initial_archived_status"
    t.date "archive_edit_date"
    t.boolean "reviewed", default: false
    t.boolean "people_problem_reason_all_office_staff", default: false
    t.boolean "people_problem_reason_short_staffed", default: false
    t.boolean "people_problem_reason_specific_people", default: false
    t.text "people_problem_specific_people"
    t.text "people_problem_details"
    t.boolean "product_problem_reason_curb_appeal", default: false
    t.boolean "product_problem_reason_unit_make_ready", default: false
    t.boolean "product_problem_reason_maintenance_staff", default: false
    t.text "product_problem_details"
    t.text "product_problem_specific_people"
    t.date "initial_archived_date"
    t.text "people_problem_fix_results"
    t.text "product_problem_fix_results"
    t.string "archived_failure_reasons"
    t.boolean "need_help_marketing_problem"
    t.boolean "need_help_marketing_problem_marketing_reviewed"
    t.boolean "need_help_capital_problem"
    t.text "need_help_capital_problem_explained"
    t.boolean "need_help_capital_problem_asset_management_reviewed"
    t.boolean "need_help_capital_problem_maintenance_reviewed"
    t.decimal "basis_triggered_value"
    t.decimal "trending_average_daily_triggered_value"
    t.decimal "physical_occupancy_triggered_value"
    t.boolean "pricing_problem_denied", default: false
    t.boolean "pricing_problem_approved", default: false
    t.boolean "pricing_problem_approved_cond", default: false
    t.text "pricing_problem_approved_cond_text"
    t.index ["archive_edit_user_id"], name: "index_blue_shifts_on_archive_edit_user_id"
    t.index ["comment_thread_id"], name: "index_blue_shifts_on_comment_thread_id"
    t.index ["metric_id"], name: "index_blue_shifts_on_metric_id"
    t.index ["need_help_comment_thread_id"], name: "index_blue_shifts_on_need_help_comment_thread_id"
    t.index ["people_problem_comment_thread_id"], name: "index_blue_shifts_on_people_problem_comment_thread_id"
    t.index ["pricing_problem_comment_thread_id"], name: "index_blue_shifts_on_pricing_problem_comment_thread_id"
    t.index ["product_problem_comment_thread_id"], name: "index_blue_shifts_on_product_problem_comment_thread_id"
    t.index ["property_id"], name: "index_blue_shifts_on_property_id"
    t.index ["user_id"], name: "index_blue_shifts_on_user_id"
  end

  create_table "calendar_bot_events", id: :serial, force: :cascade do |t|
    t.boolean "sent", default: false
    t.date "event_date"
    t.string "title"
    t.string "description"
    t.string "background_color"
    t.string "border_color"
    t.string "text_color"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["event_date"], name: "index_calendar_bot_events_on_event_date"
    t.index ["sent"], name: "index_calendar_bot_events_on_sent"
  end

  create_table "collections_by_tenant_details", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.datetime "date_time", precision: nil
    t.string "tenant_code"
    t.string "tenant_name"
    t.string "unit_code"
    t.decimal "total_charges"
    t.decimal "total_owed"
    t.boolean "payment_plan"
    t.boolean "eviction"
    t.string "mobile_phone"
    t.string "home_phone"
    t.string "office_phone"
    t.string "email"
    t.text "last_note"
    t.boolean "payment_plan_delinquent"
    t.datetime "last_note_updated_at", precision: nil
    t.index ["date_time"], name: "index_collections_by_tenant_details_on_date_time"
    t.index ["property_id"], name: "index_collections_by_tenant_details_on_property_id"
    t.index ["tenant_code"], name: "index_collections_by_tenant_details_on_tenant_code"
  end

  create_table "collections_details", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.datetime "date_time", precision: nil
    t.decimal "num_of_units"
    t.decimal "occupancy"
    t.decimal "total_charges"
    t.decimal "total_paid"
    t.decimal "total_payment_plan"
    t.decimal "total_evictions_owed"
    t.decimal "num_of_unknown"
    t.decimal "num_of_payment_plan"
    t.decimal "num_of_paid_in_full"
    t.decimal "num_of_evictions"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "paid_full_color_code"
    t.decimal "paid_full_with_pp_color_code"
    t.decimal "avg_daily_occ_adj"
    t.decimal "avg_daily_trend_2mo_adj"
    t.decimal "past_due_rents"
    t.decimal "covid_adjusted_rents"
    t.index ["date_time"], name: "index_collections_details_on_date_time"
    t.index ["num_of_units"], name: "index_collections_details_on_num_of_units"
    t.index ["property_id"], name: "index_collections_details_on_property_id"
  end

  create_table "collections_non_eviction_past20_details", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.date "date"
    t.string "yardi_code"
    t.string "tenant"
    t.string "unit"
    t.string "balance"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["date"], name: "index_collections_non_eviction_past20_details_on_date"
    t.index ["property_id"], name: "index_collections_non_eviction_past20_details_on_property_id"
    t.index ["yardi_code"], name: "index_collections_non_eviction_past20_details_on_yardi_code"
  end

  create_table "commontator_comments", id: :serial, force: :cascade do |t|
    t.string "creator_type"
    t.integer "creator_id"
    t.string "editor_type"
    t.integer "editor_id"
    t.integer "thread_id", null: false
    t.text "body", null: false
    t.datetime "deleted_at", precision: nil
    t.integer "cached_votes_up", default: 0
    t.integer "cached_votes_down", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "parent_id"
    t.index ["cached_votes_down"], name: "index_commontator_comments_on_cached_votes_down"
    t.index ["cached_votes_up"], name: "index_commontator_comments_on_cached_votes_up"
    t.index ["creator_id", "creator_type", "thread_id"], name: "index_commontator_comments_on_c_id_and_c_type_and_t_id"
    t.index ["parent_id"], name: "index_commontator_comments_on_parent_id"
    t.index ["thread_id", "created_at"], name: "index_commontator_comments_on_thread_id_and_created_at"
  end

  create_table "commontator_subscriptions", id: :serial, force: :cascade do |t|
    t.string "subscriber_type", null: false
    t.integer "subscriber_id", null: false
    t.integer "thread_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["subscriber_id", "subscriber_type", "thread_id"], name: "index_commontator_subscriptions_on_s_id_and_s_type_and_t_id", unique: true
    t.index ["thread_id"], name: "index_commontator_subscriptions_on_thread_id"
  end

  create_table "commontator_threads", id: :serial, force: :cascade do |t|
    t.string "commontable_type"
    t.integer "commontable_id"
    t.datetime "closed_at", precision: nil
    t.string "closer_type"
    t.integer "closer_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "comp_survey_by_bed_details", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.date "date"
    t.decimal "num_of_bedrooms"
    t.decimal "our_market_rent"
    t.decimal "comp_market_rent"
    t.decimal "our_occupancy"
    t.decimal "comp_occupancy"
    t.decimal "days_since_last_survey"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.date "survey_date"
    t.index ["date"], name: "index_comp_survey_by_bed_details_on_date"
    t.index ["num_of_bedrooms"], name: "index_comp_survey_by_bed_details_on_num_of_bedrooms"
    t.index ["property_id"], name: "index_comp_survey_by_bed_details_on_property_id"
  end

  create_table "compliance_issues", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.date "date"
    t.string "issue"
    t.decimal "num_of_culprits"
    t.text "culprits"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "trm_notify_only", default: false
    t.index ["property_id"], name: "index_compliance_issues_on_property_id"
  end

  create_table "conversions_for_agents", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.date "date"
    t.string "agent"
    t.decimal "prospects_10days"
    t.decimal "prospects_30days"
    t.decimal "prospects_365days"
    t.decimal "conversion_10days"
    t.decimal "conversion_30days"
    t.decimal "conversion_365days"
    t.decimal "close_10days"
    t.decimal "close_30days"
    t.decimal "close_365days"
    t.decimal "decline_30days"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "prospects_180days"
    t.decimal "conversion_180days"
    t.decimal "close_180days"
    t.boolean "is_property_data"
    t.integer "units"
    t.decimal "renewal_30days"
    t.decimal "renewal_180days"
    t.decimal "renewal_365days"
    t.decimal "shows_30days"
    t.decimal "shows_180days"
    t.decimal "shows_365days"
    t.decimal "submits_30days"
    t.decimal "submits_180days"
    t.decimal "submits_365days"
    t.decimal "declines_30days"
    t.decimal "declines_180days"
    t.decimal "declines_365days"
    t.decimal "decline_180days"
    t.decimal "decline_365days"
    t.decimal "leases_30days"
    t.decimal "leases_180days"
    t.decimal "leases_365days"
    t.decimal "num_of_leads_needed"
    t.decimal "druid_prospects_30days"
    t.index ["property_id"], name: "index_conversions_for_agents_on_property_id"
  end

  create_table "costar_market_data", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.date "date"
    t.decimal "submarket_percent_vacant"
    t.decimal "average_effective_rent"
    t.decimal "studio_effective_rent"
    t.decimal "one_bedroom_effective_rent"
    t.decimal "two_bedroom_effective_rent"
    t.decimal "three_bedroom_effective_rent"
    t.decimal "four_bedroom_effective_rent"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "in_development", default: false
    t.index ["date"], name: "index_costar_market_data_on_date"
    t.index ["property_id"], name: "index_costar_market_data_on_property_id"
  end

  create_table "data_import_records", id: :serial, force: :cascade do |t|
    t.datetime "generated_at", precision: nil
    t.datetime "data_datetime", precision: nil
    t.string "title"
    t.string "source"
    t.string "comm_type"
    t.string "data_type"
    t.boolean "data_imported"
    t.date "data_date"
    t.index ["data_datetime"], name: "index_data_import_records_on_data_datetime"
    t.index ["generated_at"], name: "index_data_import_records_on_generated_at"
    t.index ["source"], name: "index_data_import_records_on_source"
    t.index ["title"], name: "index_data_import_records_on_title"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "employees", id: :serial, force: :cascade do |t|
    t.string "employee_id"
    t.string "first_name"
    t.string "last_name"
    t.datetime "ext_created_at", precision: nil
    t.datetime "ext_person_changed_at", precision: nil
    t.datetime "ext_employment_changed_at", precision: nil
    t.datetime "date_in_job", precision: nil
    t.datetime "date_last_worked", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "date_of_birth", precision: nil
    t.string "workable_name"
    t.index ["date_in_job"], name: "index_employees_on_date_in_job"
    t.index ["employee_id"], name: "index_employees_on_employee_id"
    t.index ["ext_employment_changed_at"], name: "index_employees_on_ext_employment_changed_at"
    t.index ["ext_person_changed_at"], name: "index_employees_on_ext_person_changed_at"
    t.index ["first_name"], name: "index_employees_on_first_name"
    t.index ["last_name"], name: "index_employees_on_last_name"
  end

  create_table "images", id: :serial, force: :cascade do |t|
    t.string "caption"
    t.integer "imageable_id"
    t.string "imageable_type"
    t.string "path", limit: 2000
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["imageable_type", "imageable_id"], name: "index_images_on_imageable_type_and_imageable_id"
  end

  create_table "incomplete_work_orders", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.date "call_date"
    t.date "update_date"
    t.date "latest_import_date"
    t.string "unit"
    t.string "work_order"
    t.text "brief_desc"
    t.text "reason_incomplete"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["call_date"], name: "index_incomplete_work_orders_on_call_date"
    t.index ["latest_import_date"], name: "index_incomplete_work_orders_on_latest_import_date"
    t.index ["property_id"], name: "index_incomplete_work_orders_on_property_id"
    t.index ["work_order"], name: "index_incomplete_work_orders_on_work_order"
  end

  create_table "maint_blue_shifts", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.date "created_on"
    t.boolean "people_problem"
    t.text "people_problem_fix"
    t.date "people_problem_fix_by"
    t.boolean "vendor_problem"
    t.text "vendor_problem_fix"
    t.date "vendor_problem_fix_by"
    t.boolean "parts_problem"
    t.text "parts_problem_fix"
    t.date "parts_problem_fix_by"
    t.boolean "need_help"
    t.text "need_help_with"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.boolean "archived"
    t.string "archived_status"
    t.integer "metric_id"
    t.integer "comment_thread_id"
    t.integer "people_problem_comment_thread_id"
    t.integer "vendor_problem_comment_thread_id"
    t.integer "parts_problem_comment_thread_id"
    t.integer "need_help_comment_thread_id"
    t.integer "archive_edit_user_id"
    t.boolean "reviewed", default: false
    t.string "initial_archived_status"
    t.date "archive_edit_date"
    t.date "initial_archived_date"
    t.index ["archive_edit_user_id"], name: "index_maint_blue_shifts_on_archive_edit_user_id"
    t.index ["comment_thread_id"], name: "index_maint_blue_shifts_on_comment_thread_id"
    t.index ["metric_id"], name: "index_maint_blue_shifts_on_metric_id"
    t.index ["need_help_comment_thread_id"], name: "index_maint_blue_shifts_on_need_help_comment_thread_id"
    t.index ["parts_problem_comment_thread_id"], name: "index_maint_blue_shifts_on_parts_problem_comment_thread_id"
    t.index ["people_problem_comment_thread_id"], name: "index_maint_blue_shifts_on_people_problem_comment_thread_id"
    t.index ["property_id"], name: "index_maint_blue_shifts_on_property_id"
    t.index ["user_id"], name: "index_maint_blue_shifts_on_user_id"
    t.index ["vendor_problem_comment_thread_id"], name: "index_maint_blue_shifts_on_vendor_problem_comment_thread_id"
  end

  create_table "metrics", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.integer "position"
    t.date "date"
    t.decimal "number_of_units"
    t.decimal "physical_occupancy"
    t.decimal "cnoi"
    t.decimal "trending_average_daily"
    t.decimal "trending_next_month"
    t.decimal "occupancy_average_daily"
    t.decimal "occupancy_budgeted_economic"
    t.decimal "occupancy_average_daily_30_days_ago"
    t.decimal "average_rents_net_effective"
    t.decimal "average_rents_net_effective_budgeted"
    t.decimal "basis"
    t.decimal "basis_year_to_date"
    t.decimal "expenses_percentage_of_past_month"
    t.decimal "expenses_percentage_of_budget"
    t.decimal "renewals_number_renewed"
    t.decimal "renewals_percentage_renewed"
    t.decimal "collections_current_status_residents_with_last_month_balance"
    t.decimal "collections_unwritten_off_balances"
    t.decimal "collections_percentage_recurring_charges_collected"
    t.decimal "collections_current_status_residents_with_current_month_balance"
    t.decimal "collections_number_of_eviction_residents"
    t.decimal "maintenance_percentage_ready_over_vacant"
    t.decimal "maintenance_number_not_ready"
    t.decimal "maintenance_turns_completed"
    t.decimal "maintenance_open_wos"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "rolling_30_net_sales"
    t.decimal "rolling_10_net_sales"
    t.decimal "leases_attained"
    t.decimal "leases_goal"
    t.string "leases_alert_message"
    t.decimal "leases_attained_no_monies"
    t.decimal "average_market_rent"
    t.decimal "average_rent_delta_percent"
    t.decimal "renewals_unknown"
    t.decimal "leases_last_24hrs"
    t.boolean "leases_last_24hrs_applied"
    t.decimal "maintenance_total_open_work_orders"
    t.decimal "maintenance_vacants_over_nine_days"
    t.decimal "average_rent_weighted_per_unit_specials"
    t.decimal "average_rent_year_over_year_without_vacancy"
    t.decimal "average_rent_year_over_year_with_vacancy"
    t.decimal "concessions_per_unit"
    t.decimal "concessions_budgeted_per_unit"
    t.decimal "average_days_vacant_over_seven"
    t.decimal "denied_applications_current_month"
    t.decimal "collections_eviction_residents_over_two_months_due"
    t.decimal "renewals_residents_month_to_month"
    t.decimal "budgeted_trended_occupancy"
    t.decimal "projected_cnoi"
    t.decimal "renewals_ytd_percentage"
    t.decimal "average_rent_1bed_net_effective"
    t.decimal "average_rent_1bed_new_leases"
    t.decimal "average_rent_1bed_renewal_leases"
    t.decimal "average_rent_2bed_net_effective"
    t.decimal "average_rent_2bed_new_leases"
    t.decimal "average_rent_2bed_renewal_leases"
    t.decimal "average_rent_3bed_net_effective"
    t.decimal "average_rent_3bed_new_leases"
    t.decimal "average_rent_3bed_renewal_leases"
    t.decimal "average_rent_4bed_net_effective"
    t.decimal "average_rent_4bed_new_leases"
    t.decimal "average_rent_4bed_renewal_leases"
    t.boolean "addendum_received", default: false
    t.boolean "main_metrics_received", default: false
    t.index ["property_id", "date"], name: "index_metrics_on_property_id_and_date"
    t.index ["property_id"], name: "index_metrics_on_property_id"
  end

  create_table "properties", id: :serial, force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "blue_shift_status"
    t.integer "current_blue_shift_id"
    t.string "slack_channel"
    t.string "full_name"
    t.integer "manager_strikes", default: 0, null: false
    t.integer "current_maint_blue_shift_id"
    t.string "maint_blue_shift_status"
    t.integer "team_id"
    t.boolean "active"
    t.string "type"
    t.string "city"
    t.string "state"
    t.integer "current_trm_blue_shift_id"
    t.string "trm_blue_shift_status"
    t.string "sparkle_blshift_pm_templ_name"
    t.string "logo"
    t.string "image"
    t.integer "num_of_units"
    t.datetime "last_no_blue_shift_needed", precision: nil
    t.index ["code"], name: "index_properties_on_code", unique: true
    t.index ["current_blue_shift_id"], name: "index_properties_on_current_blue_shift_id"
    t.index ["current_maint_blue_shift_id"], name: "index_properties_on_current_maint_blue_shift_id"
    t.index ["current_trm_blue_shift_id"], name: "index_properties_on_current_trm_blue_shift_id"
  end

  create_table "properties_users", id: false, force: :cascade do |t|
    t.integer "property_id"
    t.integer "user_id"
    t.index ["property_id"], name: "index_properties_users_on_property_id"
    t.index ["user_id"], name: "index_properties_users_on_user_id"
  end

  create_table "property_units", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.boolean "model"
    t.string "remoteid"
    t.string "name"
    t.integer "bedrooms"
    t.integer "bathrooms"
    t.integer "sqft"
    t.string "occupancy"
    t.string "lease_status"
    t.date "vacate_on"
    t.date "made_ready_on"
    t.float "market_rent"
    t.string "unit_type"
    t.string "floorplan_name"
    t.boolean "rent_ready"
    t.integer "days_vacant"
    t.integer "days_vacant_to_ready"
    t.integer "days_ready_to_leased"
    t.integer "days_ready_to_occupied"
    t.integer "prev_days_vacant"
    t.integer "prev_days_vacant_to_ready"
    t.integer "prev_days_ready_to_leased"
    t.integer "prev_days_ready_to_occupied"
    t.datetime "data_start_datetime", precision: nil
    t.datetime "occupied_start_datetime", precision: nil
    t.datetime "occupied_end_datetime", precision: nil
    t.datetime "vacant_start_datetime", precision: nil
    t.datetime "vacant_end_datetime", precision: nil
    t.datetime "rent_ready_start_datetime", precision: nil
    t.datetime "rent_ready_end_datetime", precision: nil
    t.datetime "leased_start_datetime", precision: nil
    t.datetime "leased_end_datetime", precision: nil
    t.datetime "occupied_prev_start_datetime", precision: nil
    t.datetime "occupied_prev_end_datetime", precision: nil
    t.datetime "vacant_prev_start_datetime", precision: nil
    t.datetime "vacant_prev_end_datetime", precision: nil
    t.datetime "rent_ready_prev_start_datetime", precision: nil
    t.datetime "rent_ready_prev_end_datetime", precision: nil
    t.datetime "leased_prev_start_datetime", precision: nil
    t.datetime "leased_prev_end_datetime", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["model"], name: "index_property_units_on_model"
    t.index ["property_id"], name: "index_property_units_on_property_id"
    t.index ["remoteid"], name: "index_property_units_on_remoteid"
  end

  create_table "renewals_unknown_details", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.date "date"
    t.string "yardi_code"
    t.string "tenant"
    t.string "unit"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["date"], name: "index_renewals_unknown_details_on_date"
    t.index ["property_id"], name: "index_renewals_unknown_details_on_property_id"
    t.index ["yardi_code"], name: "index_renewals_unknown_details_on_yardi_code"
  end

  create_table "rent_change_reasons", id: :serial, force: :cascade do |t|
    t.integer "metric_id"
    t.string "unit_type_code"
    t.decimal "old_market_rent"
    t.decimal "percent_change"
    t.decimal "change_amount"
    t.string "trigger"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "new_rent"
    t.decimal "average_daily_occupancy_trend_30days_out"
    t.decimal "average_daily_occupancy_trend_60days_out"
    t.decimal "average_daily_occupancy_trend_90days_out"
    t.decimal "last_survey_days_ago"
    t.decimal "num_of_units"
    t.integer "property_id"
    t.date "date"
    t.integer "units_vacant_not_leased"
    t.integer "units_on_notice_not_leased"
    t.float "last_three_rent"
    t.index ["metric_id", "unit_type_code"], name: "index_rent_change_reasons_on_metric_id_and_unit_type_code"
    t.index ["metric_id"], name: "index_rent_change_reasons_on_metric_id"
    t.index ["property_id"], name: "index_rent_change_reasons_on_property_id"
  end

  create_table "sales_for_agents", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.date "date"
    t.string "agent"
    t.integer "sales"
    t.integer "goal"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "star_received"
    t.integer "sales_prior_month"
    t.integer "super_star_goal"
    t.boolean "super_star_received", default: false
    t.boolean "missed_goal", default: false
    t.integer "goal_for_slack"
    t.string "agent_email"
    t.index ["property_id"], name: "index_sales_for_agents_on_property_id"
  end

  create_table "stat_records", id: :serial, force: :cascade do |t|
    t.date "generated_at"
    t.string "source"
    t.string "name"
    t.string "url"
    t.json "data"
    t.text "raw"
    t.boolean "success"
    t.text "response"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["success", "generated_at", "created_at"], name: "stat_record_query_idx"
  end

  create_table "trm_blue_shifts", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.integer "metric_id"
    t.integer "user_id"
    t.date "created_on"
    t.boolean "manager_problem"
    t.text "manager_problem_details"
    t.text "manager_problem_fix"
    t.text "manager_problem_results"
    t.date "manager_problem_fix_by"
    t.boolean "market_problem"
    t.text "market_problem_details"
    t.boolean "marketing_problem"
    t.text "marketing_problem_details"
    t.text "marketing_problem_fix"
    t.date "marketing_problem_fix_by"
    t.boolean "capital_problem"
    t.text "capital_problem_details"
    t.boolean "archived"
    t.string "archived_status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "archive_edit_user_id"
    t.string "initial_archived_status"
    t.date "archive_edit_date"
    t.integer "comment_thread_id"
    t.integer "manager_problem_comment_thread_id"
    t.integer "market_problem_comment_thread_id"
    t.integer "marketing_problem_comment_thread_id"
    t.integer "capital_problem_comment_thread_id"
    t.date "initial_archived_date"
    t.boolean "vp_reviewed"
    t.index ["archive_edit_user_id"], name: "index_trm_blue_shifts_on_archive_edit_user_id"
    t.index ["capital_problem_comment_thread_id"], name: "index_trm_blue_shifts_on_capital_problem_comment_thread_id"
    t.index ["comment_thread_id"], name: "index_trm_blue_shifts_on_comment_thread_id"
    t.index ["manager_problem_comment_thread_id"], name: "index_trm_blue_shifts_on_manager_problem_comment_thread_id"
    t.index ["market_problem_comment_thread_id"], name: "index_trm_blue_shifts_on_market_problem_comment_thread_id"
    t.index ["marketing_problem_comment_thread_id"], name: "index_trm_blue_shifts_on_marketing_problem_comment_thread_id"
    t.index ["metric_id"], name: "index_trm_blue_shifts_on_metric_id"
    t.index ["property_id"], name: "index_trm_blue_shifts_on_property_id"
    t.index ["user_id"], name: "index_trm_blue_shifts_on_user_id"
  end

  create_table "turns_for_properties", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.date "date"
    t.decimal "turned_t9d"
    t.decimal "total_vnr_9days_ago"
    t.decimal "percent_turned_t9d"
    t.decimal "total_vnr"
    t.decimal "wo_completed_yesterday"
    t.decimal "wo_open_over_48hrs"
    t.decimal "wo_percent_completed_t30"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["property_id"], name: "index_turns_for_properties_on_property_id"
  end

  create_table "user_properties", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "property_id"
    t.string "blue_shift_status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "maint_blue_shift_status"
    t.string "trm_blue_shift_status"
    t.index ["property_id"], name: "index_user_properties_on_property_id"
    t.index ["user_id"], name: "index_user_properties_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "invitation_token"
    t.datetime "invitation_created_at", precision: nil
    t.datetime "invitation_sent_at", precision: nil
    t.datetime "invitation_accepted_at", precision: nil
    t.integer "invitation_limit"
    t.integer "invited_by_id"
    t.string "invited_by_type"
    t.integer "invitations_count", default: 0
    t.string "role"
    t.string "first_name"
    t.string "last_name"
    t.string "slack_username"
    t.boolean "active"
    t.string "t1_role"
    t.string "t2_role"
    t.integer "team_id"
    t.boolean "view_all_properties", default: false
    t.string "slack_corp_username"
    t.string "profile_image"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "workable_jobs", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.string "shortcode"
    t.string "state"
    t.datetime "job_created_at", precision: nil
    t.string "title"
    t.string "code"
    t.string "department"
    t.string "url"
    t.string "application_url"
    t.string "last_activity_member_name"
    t.datetime "last_activity_member_datetime", precision: nil
    t.string "last_activity_member_action"
    t.string "last_activity_member_stage_name"
    t.datetime "last_activity_candidate_datetime", precision: nil
    t.string "last_activity_candidate_action"
    t.string "last_activity_candidate_stage_name"
    t.datetime "last_offer_sent_at", precision: nil
    t.datetime "hired_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_duplicate", default: false
    t.boolean "is_repost", default: false
    t.datetime "original_job_created_at", precision: nil
    t.datetime "offer_accepted_at", precision: nil
    t.datetime "background_check_requested_at", precision: nil
    t.datetime "background_check_completed_at", precision: nil
    t.boolean "is_void", default: false
    t.boolean "is_hired", default: false
    t.string "hired_candidate_name"
    t.string "hired_candidate_first_name"
    t.string "hired_candidate_last_name"
    t.integer "employee_id"
    t.datetime "employee_date_in_job", precision: nil
    t.datetime "employee_date_last_worked", precision: nil
    t.integer "num_of_offers_sent"
    t.datetime "employee_updated_at", precision: nil
    t.boolean "can_post", default: true
    t.boolean "new_property", default: false
    t.integer "other_num_of_offers_sent", default: 0
    t.string "employee_first_name_override"
    t.string "employee_last_name_override"
    t.boolean "employee_ignore", default: false
    t.index ["employee_id"], name: "index_workable_jobs_on_employee_id"
    t.index ["hired_at"], name: "index_workable_jobs_on_hired_at"
    t.index ["job_created_at"], name: "index_workable_jobs_on_job_created_at"
    t.index ["property_id"], name: "index_workable_jobs_on_property_id"
    t.index ["shortcode"], name: "index_workable_jobs_on_shortcode"
    t.index ["state"], name: "index_workable_jobs_on_state"
  end

  add_foreign_key "accounts_payable_compliance_issues", "properties"
  add_foreign_key "average_rents_bedroom_details", "properties"
  add_foreign_key "blue_shifts", "commontator_threads", column: "comment_thread_id"
  add_foreign_key "blue_shifts", "commontator_threads", column: "need_help_comment_thread_id"
  add_foreign_key "blue_shifts", "commontator_threads", column: "people_problem_comment_thread_id"
  add_foreign_key "blue_shifts", "commontator_threads", column: "pricing_problem_comment_thread_id"
  add_foreign_key "blue_shifts", "commontator_threads", column: "product_problem_comment_thread_id"
  add_foreign_key "blue_shifts", "metrics"
  add_foreign_key "blue_shifts", "properties"
  add_foreign_key "blue_shifts", "users"
  add_foreign_key "blue_shifts", "users", column: "archive_edit_user_id"
  add_foreign_key "collections_by_tenant_details", "properties"
  add_foreign_key "collections_details", "properties"
  add_foreign_key "collections_non_eviction_past20_details", "properties"
  add_foreign_key "commontator_comments", "commontator_comments", column: "parent_id", on_update: :restrict, on_delete: :cascade
  add_foreign_key "comp_survey_by_bed_details", "properties"
  add_foreign_key "compliance_issues", "properties"
  add_foreign_key "conversions_for_agents", "properties"
  add_foreign_key "costar_market_data", "properties"
  add_foreign_key "incomplete_work_orders", "properties"
  add_foreign_key "maint_blue_shifts", "commontator_threads", column: "comment_thread_id"
  add_foreign_key "maint_blue_shifts", "commontator_threads", column: "need_help_comment_thread_id"
  add_foreign_key "maint_blue_shifts", "commontator_threads", column: "parts_problem_comment_thread_id"
  add_foreign_key "maint_blue_shifts", "commontator_threads", column: "people_problem_comment_thread_id"
  add_foreign_key "maint_blue_shifts", "commontator_threads", column: "vendor_problem_comment_thread_id"
  add_foreign_key "maint_blue_shifts", "metrics"
  add_foreign_key "maint_blue_shifts", "properties"
  add_foreign_key "maint_blue_shifts", "users"
  add_foreign_key "maint_blue_shifts", "users", column: "archive_edit_user_id"
  add_foreign_key "metrics", "properties"
  add_foreign_key "properties", "blue_shifts", column: "current_blue_shift_id"
  add_foreign_key "properties", "maint_blue_shifts", column: "current_maint_blue_shift_id"
  add_foreign_key "properties", "trm_blue_shifts", column: "current_trm_blue_shift_id"
  add_foreign_key "property_units", "properties"
  add_foreign_key "renewals_unknown_details", "properties"
  add_foreign_key "rent_change_reasons", "metrics"
  add_foreign_key "rent_change_reasons", "properties"
  add_foreign_key "sales_for_agents", "properties"
  add_foreign_key "trm_blue_shifts", "commontator_threads", column: "capital_problem_comment_thread_id"
  add_foreign_key "trm_blue_shifts", "commontator_threads", column: "comment_thread_id"
  add_foreign_key "trm_blue_shifts", "commontator_threads", column: "manager_problem_comment_thread_id"
  add_foreign_key "trm_blue_shifts", "commontator_threads", column: "market_problem_comment_thread_id"
  add_foreign_key "trm_blue_shifts", "commontator_threads", column: "marketing_problem_comment_thread_id"
  add_foreign_key "trm_blue_shifts", "metrics"
  add_foreign_key "trm_blue_shifts", "properties"
  add_foreign_key "trm_blue_shifts", "users"
  add_foreign_key "trm_blue_shifts", "users", column: "archive_edit_user_id"
  add_foreign_key "turns_for_properties", "properties"
  add_foreign_key "user_properties", "properties"
  add_foreign_key "user_properties", "users"
  add_foreign_key "workable_jobs", "employees"
  add_foreign_key "workable_jobs", "properties"
end
