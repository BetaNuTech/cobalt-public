class AddNewPropertyToWorkableJobs < ActiveRecord::Migration
  def change
    add_column :workable_jobs, :new_property, :boolean, default: false
  end
end
