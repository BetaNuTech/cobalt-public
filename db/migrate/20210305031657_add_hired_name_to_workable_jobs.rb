class AddHiredNameToWorkableJobs < ActiveRecord::Migration
  def change
    add_column :workable_jobs, :hired_candidate_name, :string
    add_column :workable_jobs, :hired_candidate_first_name, :string, index: true
    add_column :workable_jobs, :hired_candidate_last_name, :string, index: true

    add_index :workable_jobs, :hired_at

    add_reference :workable_jobs, :employee, references: :employees, index: true
    add_foreign_key :workable_jobs, :employees, column: :employee_id
  end
end
