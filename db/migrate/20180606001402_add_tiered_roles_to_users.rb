class AddTieredRolesToUsers < ActiveRecord::Migration
  def up
    add_column :users, :t1_role, :string        
    add_column :users, :t2_role, :string     
    
    execute("UPDATE users SET t1_role = 'admin' WHERE role = 'admin'")
    execute("UPDATE users SET t1_role = 'corporate' WHERE role = 'corporate' OR role = 'corp_property_manager' OR role = 'corp_maint_super'")
    execute("UPDATE users SET t1_role = 'property' WHERE role = 'property_manager' OR role = 'maint_super'")
    execute("UPDATE users SET t2_role = 'property_manager' WHERE role = 'property_manager' OR role = 'corp_property_manager'")
    execute("UPDATE users SET t2_role = 'maint_super' WHERE role = 'maint_super' OR role = 'corp_maint_super'")
    execute("UPDATE users SET t2_role = 'NA' WHERE role = 'admin' OR role = 'corporate'")
  end

  def down
    remove_column :users, :t1_role        
    remove_column :users, :t2_role
  end



end
