class AddIndexToStatRecords < ActiveRecord::Migration
  def change
    add_index :stat_records, [:success, :generated_at, :created_at], name: 'stat_record_query_idx'
  end
end
