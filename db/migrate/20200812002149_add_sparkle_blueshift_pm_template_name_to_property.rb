class AddSparkleBlueshiftPmTemplateNameToProperty < ActiveRecord::Migration
  def change
    add_column :properties, :sparkle_blshift_pm_templ_name, :string
  end
end
