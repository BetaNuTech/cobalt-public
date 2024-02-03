class AddEmployeeNameOverrideToWorkableJobs < ActiveRecord::Migration
  def change
    add_column :workable_jobs, :employee_first_name_override, :string
    add_column :workable_jobs, :employee_last_name_override, :string
    add_column :workable_jobs, :employee_ignore, :boolean, :default => false
  end
end
