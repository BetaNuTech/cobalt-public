class CreateIncompleteWorkOrders < ActiveRecord::Migration
  def change
    create_table :incomplete_work_orders do |t|
      t.references :property, index: true, foreign_key: true
      t.date :call_date, index: true
      t.date :update_date
      t.date :latest_import_date, index: true
      t.string :unit
      t.string :work_order, index: true
      t.text :brief_desc
      t.text :reason_incomplete

      t.timestamps null: false
    end
  end
end
