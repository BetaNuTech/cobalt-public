class CreateDataImportRecords < ActiveRecord::Migration
  def change
    create_table :data_import_records do |t|
      t.datetime :generated_at, index: true
      t.datetime :data_datetime, index: true
      t.string :title, index: true
      t.string :source, index: true
      t.string :comm_type
      t.string :data_type
      t.boolean :data_imported
    end
  end
end
