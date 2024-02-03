class CreateUserProperties < ActiveRecord::Migration
  def change
    create_table :user_properties do |t|
      t.references :user, index: true, foreign_key: true
      t.references :property, index: true, foreign_key: true
      t.string :blue_shift_status

      t.timestamps null: false
    end
  end
end
