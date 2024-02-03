class AddOtherNumOfOffersSentToWorkableJobs < ActiveRecord::Migration
  def change
    add_column :workable_jobs, :other_num_of_offers_sent, :integer, default: 0
  end
end
