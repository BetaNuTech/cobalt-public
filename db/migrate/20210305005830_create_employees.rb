class CreateEmployees < ActiveRecord::Migration
  def change
    create_table :employees do |t|
      t.string :employee_id, index: true
      t.string :first_name, index: true
      t.string :last_name, index: true

      t.datetime :ext_created_at
      t.datetime :ext_person_changed_at, index: true
      t.datetime :ext_employment_changed_at, index: true
      t.datetime :date_in_job, index: true
      t.datetime :date_last_worked

      t.timestamps null: false
    end
  end
end
