class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.string :caption
      t.references :imageable, index: true, polymorphic: true
      t.string :path, limit: 2000

      t.timestamps null: false
    end
  end
end
