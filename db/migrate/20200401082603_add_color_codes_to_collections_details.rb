class AddColorCodesToCollectionsDetails < ActiveRecord::Migration
  def change
    add_column :collections_details, :paid_full_color_code, :decimal
    add_column :collections_details, :paid_full_with_pp_color_code, :decimal
  end
end
