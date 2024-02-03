class AddIsVoidToWorkableJobs < ActiveRecord::Migration
  def change
    add_column :workable_jobs, :is_void, :boolean, :default => false
  end
end
