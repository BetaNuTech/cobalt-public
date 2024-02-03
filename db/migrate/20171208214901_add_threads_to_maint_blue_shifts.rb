class AddThreadsToMaintBlueShifts < ActiveRecord::Migration
  def up
    add_reference :maint_blue_shifts, :comment_thread, references: :commontator_thread, index: true
    add_foreign_key :maint_blue_shifts, :commontator_threads, column: :comment_thread_id
    
    add_reference :maint_blue_shifts, :people_problem_comment_thread, references: :commontator_thread, index: true
    add_foreign_key :maint_blue_shifts, :commontator_threads, column: :people_problem_comment_thread_id
    
    add_reference :maint_blue_shifts, :vendor_problem_comment_thread, references: :commontator_thread, index: true
    add_foreign_key :maint_blue_shifts, :commontator_threads, column: :vendor_problem_comment_thread_id
    
    add_reference :maint_blue_shifts, :parts_problem_comment_thread, references: :commontator_thread, index: true
    add_foreign_key :maint_blue_shifts, :commontator_threads, column: :parts_problem_comment_thread_id
    
    add_reference :maint_blue_shifts, :need_help_comment_thread, references: :commontator_thread, index: true
    add_foreign_key :maint_blue_shifts, :commontator_threads, column: :need_help_comment_thread_id
  end
  
  def down
    remove_column :maint_blue_shifts, :comment_thread_id
    remove_column :maint_blue_shifts, :people_problem_comment_thread_id
    remove_column :maint_blue_shifts, :vendor_problem_comment_thread_id
    remove_column :maint_blue_shifts, :parts_problem_comment_thread_id
    remove_column :maint_blue_shifts, :need_help_comment_thread_id
  end
end
