class CreateMaintBlueShifts < ActiveRecord::Migration
  def change
    create_table :maint_blue_shifts do |t|
      t.references :property, index: true, foreign_key: true
      t.date :created_on
      t.boolean :people_problem
      t.text :people_problem_fix
      t.date :people_problem_fix_by
      t.boolean :vendor_problem
      t.text :vendor_problem_fix
      t.date :vendor_problem_fix_by
      t.boolean :parts_problem
      t.text :parts_problem_fix
      t.date :parts_problem_fix_by
      t.boolean :need_help
      t.text :need_help_with
      t.timestamps null: false
      t.references :user, index: true, foreign_key: true
      t.boolean :archived
      t.string :archived_status
      t.references :metric, index: true, foreign_key: true      
    end
  end
end
