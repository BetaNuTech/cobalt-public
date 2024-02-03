class AddAverageRentSpecialsAndYoYToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :average_rent_weighted_per_unit_specials, :decimal
    add_column :metrics, :average_rent_year_over_year_without_vacancy, :decimal
    add_column :metrics, :average_rent_year_over_year_with_vacancy, :decimal
  end
end
