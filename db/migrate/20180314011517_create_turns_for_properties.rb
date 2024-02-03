class CreateTurnsForProperties < ActiveRecord::Migration
  def change
    create_table :turns_for_properties do |t|
      t.references :property, index: true, foreign_key: true
      t.date :date
      t.decimal :turned_t9d
      t.decimal :total_vnr_9days_ago
      t.decimal :percent_turned_t9d
      t.decimal :total_vnr
      t.decimal :wo_completed_yesterday
      t.decimal :wo_open_over_48hrs
      t.decimal :wo_percent_completed_t30
      
      t.timestamps null: false
    end
  end
end
