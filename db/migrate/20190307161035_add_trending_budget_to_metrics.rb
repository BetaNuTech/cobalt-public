class AddTrendingBudgetToMetrics < ActiveRecord::Migration
  def up
    change_table :metrics do |t|
      t.decimal :budgeted_trended_occupancy
    end

    BlueShift.find_each do |blue_shift|
      blue_shift.basis_triggered_value = Properties::Commands::CheckBlueShiftRequirement.blueshift_required_for_basis_value?(blue_shift.property, blue_shift.metric.date)
      blue_shift.trending_average_daily_triggered_value = Properties::Commands::CheckBlueShiftRequirement.blueshift_required_for_trending_average_daily_value?(blue_shift.property, blue_shift.metric.date)
      blue_shift.physical_occupancy_triggered_value = Properties::Commands::CheckBlueShiftRequirement.blueshift_required_for_physical_occupancy_value?(blue_shift.property, blue_shift.metric.date)
      blue_shift.save(validate: false)
    end

    Property.properties.where(active: true).each do |p|
      Property.update_property_blue_shift_status(p, Date.today, false)
    end
  end

  def down
    remove_column :metrics, :budgeted_trended_occupancy
  end
end
