class CreateCollectionsNonEvictionPast20Details < ActiveRecord::Migration
  def change
    create_table :collections_non_eviction_past20_details do |t|
      t.references :property, index: true, foreign_key: true
      t.date :date, index: true
      t.string :yardi_code, index: true
      t.string :tenant
      t.string :unit
      t.string :balance

      t.timestamps null: false
    end
  end
end
