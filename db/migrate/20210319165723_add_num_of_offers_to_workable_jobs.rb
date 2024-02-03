class AddNumOfOffersToWorkableJobs < ActiveRecord::Migration
  def change
    add_column :workable_jobs, :num_of_offers_sent, :integer
  end
end
