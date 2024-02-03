class AddTrmNotifyOnlyToComplianceIssues < ActiveRecord::Migration
  def change
    add_column :compliance_issues, :trm_notify_only, :boolean, :default => false
  end
end
