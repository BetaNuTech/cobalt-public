class AddEmployeeUpdatedAtToWorkableJobs < ActiveRecord::Migration
  def change
    add_column :workable_jobs, :employee_updated_at, :datetime
  end
end
