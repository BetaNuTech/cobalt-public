class AddYtdRenewalPercentageToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :renewals_ytd_percentage, :decimal
  end
end
