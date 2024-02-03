class AddContactInfoToCollectionsDetailsByTenantDetails < ActiveRecord::Migration
  def change
    add_column :collections_by_tenant_details, :mobile_phone, :string
    add_column :collections_by_tenant_details, :home_phone, :string
    add_column :collections_by_tenant_details, :office_phone, :string
    add_column :collections_by_tenant_details, :email, :string
    add_column :collections_by_tenant_details, :last_note, :text
  end
end
