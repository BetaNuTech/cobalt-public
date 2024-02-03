class AddRenewalMtmToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :renewals_residents_month_to_month, :decimal
  end
end
