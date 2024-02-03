class AddLastNoteUpdateToCollectionsByTenant < ActiveRecord::Migration
  def change
    add_column :collections_by_tenant_details, :last_note_updated_at, :datetime
  end
end
