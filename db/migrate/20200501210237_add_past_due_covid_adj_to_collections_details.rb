class AddPastDueCovidAdjToCollectionsDetails < ActiveRecord::Migration
  def change
    add_column :collections_details, :past_due_rents, :decimal
    add_column :collections_details, :covid_adjusted_rents, :decimal
  end
end
