class AddDataDateToDataImportRecords < ActiveRecord::Migration
  def change
    add_column :data_import_records, :data_date, :date, index: true
  end
end
