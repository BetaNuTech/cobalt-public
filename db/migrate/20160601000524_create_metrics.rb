class CreateMetrics < ActiveRecord::Migration
  def change
    create_table :metrics do |t|
      t.references :property, index: true, foreign_key: true
      t.integer :position
      t.date :date
      t.decimal :number_of_units
      t.decimal :physical_occupacy
      t.decimal :cnoi
      t.decimal :trending_average_daily
      t.decimal :trending_next_month
      t.decimal :occupancy_average_daily
      t.decimal :occupancy_budgeted_economic
      t.decimal :occupancy_average_daily_30_days_ago
      t.decimal :average_rents_net_effective
      t.decimal :average_rents_net_effective_budgeted
      t.decimal :basis
      t.decimal :basis_year_to_date
      t.decimal :expenses_percentage_of_past_month
      t.decimal :expenses_percentage_of_budget
      t.decimal :renewals_number_renewed
      t.decimal :renewals_percentage_renewed
      t.decimal :collections_current_status_residents_with_last_month_balance
      t.decimal :collections_unwritten_off_balances
      t.decimal :collections_percentage_recurring_charges_collected
      t.decimal :collections_current_status_residents_with_current_month_balance
      t.decimal :collections_number_of_eviction_residents
      t.decimal :maintenance_percentage_ready_over_vacant
      t.decimal :maintenance_number_not_ready
      t.decimal :maintenance_turns_completed
      t.decimal :maintenance_open_wos

      t.timestamps null: false
    end
  end
end
