class CreateComplianceIssues < ActiveRecord::Migration
  def change
    create_table :compliance_issues do |t|
      t.references :property, index: true, foreign_key: true
      t.date :date
      t.string :issue
      t.decimal :num_of_culprits
      t.string :culprits

      t.timestamps null: false
    end
  end
end
