class RenameEvictionResidentsOverTwoMonthsDue < ActiveRecord::Migration
  def change
    rename_column :metrics, :eviction_residents_over_two_months_due, :collections_eviction_residents_over_two_months_due
  end
end
