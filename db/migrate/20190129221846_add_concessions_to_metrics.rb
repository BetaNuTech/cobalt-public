class AddConcessionsToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :concessions_per_unit, :decimal
    add_column :metrics, :concessions_budgeted_per_unit, :decimal
  end
end
