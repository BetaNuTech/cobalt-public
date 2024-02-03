class AddIsHiredToWorkableJobs < ActiveRecord::Migration
  def change
    add_column :workable_jobs, :is_hired, :boolean, :default => false, index: true
  end
end
