class CreateWorkableJobs < ActiveRecord::Migration
  def change
    create_table :workable_jobs do |t|
      t.references :property, index: true, foreign_key: true
      t.string :shortcode, index: true
      t.string :state, index: true
      t.datetime :job_created_at, index: true
      
      t.string :title
      t.string :code
      t.string :department
      t.string :url
      t.string :application_url

      t.string   :last_activity_member_name
      t.datetime :last_activity_member_datetime
      t.string   :last_activity_member_action
      t.string   :last_activity_member_stage_name

      t.datetime :last_activity_candidate_datetime
      t.string   :last_activity_candidate_action
      t.string   :last_activity_candidate_stage_name

      t.datetime :last_offer_sent_at
      t.datetime :hired_at

      t.timestamps null: false
    end
  end
end
