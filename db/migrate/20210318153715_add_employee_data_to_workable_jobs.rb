class AddEmployeeDataToWorkableJobs < ActiveRecord::Migration
  def change
    add_column :workable_jobs, :employee_date_in_job, :datetime
    add_column :workable_jobs, :employee_date_last_worked, :datetime
  end
end
