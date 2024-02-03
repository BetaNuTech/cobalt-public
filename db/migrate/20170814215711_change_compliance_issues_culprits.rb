class ChangeComplianceIssuesCulprits < ActiveRecord::Migration
  def change
    change_column :compliance_issues, :culprits, :text
  end
end
