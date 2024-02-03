class AddCanPostToWorkableJobs < ActiveRecord::Migration
  def change
    add_column :workable_jobs, :can_post, :boolean, default: true
  end
end
