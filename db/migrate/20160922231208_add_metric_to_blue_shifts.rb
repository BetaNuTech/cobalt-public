  class AddMetricToBlueShifts < ActiveRecord::Migration
  def up
    add_reference :blue_shifts, :metric, index: true, foreign_key: true
    
    execute("UPDATE blue_shifts SET metric_id = (SELECT id FROM metrics WHERE metrics.property_id = blue_shifts.property_id AND metrics.date = (blue_shifts.created_on - INTERVAL '1 day') ORDER BY metrics.date DESC LIMIT 1)")
  end
  
  def down
    remove_column :blue_shifts, :metric_id
  end
end
