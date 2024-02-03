class AddDetailsToWorkableJobs < ActiveRecord::Migration
  def change
    add_column :workable_jobs, :is_duplicate, :boolean, :default => false
    add_column :workable_jobs, :is_repost, :boolean, :default => false
    add_column :workable_jobs, :original_job_created_at, :datetime
    add_column :workable_jobs, :offer_accepted_at, :datetime
    add_column :workable_jobs, :background_check_requested_at, :datetime
    add_column :workable_jobs, :background_check_completed_at, :datetime
  end
end
