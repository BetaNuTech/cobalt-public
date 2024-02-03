class AddProjectCnoiToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :projected_cnoi, :decimal
  end
end
