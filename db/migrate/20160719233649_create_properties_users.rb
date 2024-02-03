class CreatePropertiesUsers < ActiveRecord::Migration
  def change
    create_table :properties_users, id: false do |t|
      t.belongs_to :property, index: true
      t.belongs_to :user, index: true
    end
  end
end
