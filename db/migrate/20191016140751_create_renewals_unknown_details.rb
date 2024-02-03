class CreateRenewalsUnknownDetails < ActiveRecord::Migration
  def change
    create_table :renewals_unknown_details do |t|
      t.references :property, index: true, foreign_key: true
      t.date :date, index: true
      t.string :yardi_code, index: true
      t.string :tenant
      t.string :unit

      t.timestamps null: false
    end
  end
end
