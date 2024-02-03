class ChangeStatRecordsRaw < ActiveRecord::Migration
  def change
    change_column :stat_records, :raw, :text
  end
end
