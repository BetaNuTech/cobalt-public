class AddVacantUnitsAndNoticeUnitsToRentChangeReasons < ActiveRecord::Migration
  def change
    add_column :rent_change_reasons, :units_vacant_not_leased, :integer
    add_column :rent_change_reasons, :units_on_notice_not_leased, :integer
  end
end
