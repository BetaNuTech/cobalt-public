class CreateStatRecords < ActiveRecord::Migration
  def change
    create_table :stat_records do |t|
      t.date :generated_at
      t.string :source
      t.string :name
      t.string :url
      t.json :data
      t.json :raw
      t.boolean :success
      t.text :response

      t.timestamps null: false
    end
  end
end
