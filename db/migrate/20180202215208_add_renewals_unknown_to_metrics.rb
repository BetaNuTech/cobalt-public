class AddRenewalsUnknownToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :renewals_unknown, :decimal
  end
end
