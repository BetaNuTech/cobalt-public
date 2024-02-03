class AddPropertyToRentChangeReasons < ActiveRecord::Migration
  def up
    add_reference :rent_change_reasons, :property, index: true, foreign_key: true
    add_column :rent_change_reasons, :date, :date, index: true
    
    execute("UPDATE rent_change_reasons
      SET property_id = (
      SELECT property_id
      FROM metrics
      WHERE metrics.id = rent_change_reasons.metric_id);")

    execute("UPDATE rent_change_reasons
      SET date = (
      SELECT date
      FROM metrics
      WHERE metrics.id = rent_change_reasons.metric_id);")
  end

  def down
    remove_reference :rent_change_reasons, :property
    remove_column :rent_change_reasons, :date
  end
end
