class AddCommentTreadsToTrmBlueShifts < ActiveRecord::Migration
  def up
    add_reference :trm_blue_shifts, :comment_thread, references: :commontator_thread, index: true
    add_foreign_key :trm_blue_shifts, :commontator_threads, column: :comment_thread_id
    
    add_reference :trm_blue_shifts, :manager_problem_comment_thread, references: :commontator_thread, index: true
    add_foreign_key :trm_blue_shifts, :commontator_threads, column: :manager_problem_comment_thread_id
    
    add_reference :trm_blue_shifts, :market_problem_comment_thread, references: :commontator_thread, index: true
    add_foreign_key :trm_blue_shifts, :commontator_threads, column: :market_problem_comment_thread_id
    
    add_reference :trm_blue_shifts, :marketing_problem_comment_thread, references: :commontator_thread, index: true
    add_foreign_key :trm_blue_shifts, :commontator_threads, column: :marketing_problem_comment_thread_id
    
    add_reference :trm_blue_shifts, :capital_problem_comment_thread, references: :commontator_thread, index: true
    add_foreign_key :trm_blue_shifts, :commontator_threads, column: :capital_problem_comment_thread_id
  end
  
  def down
    remove_column :trm_blue_shifts, :comment_thread_id
    remove_column :trm_blue_shifts, :manager_problem_comment_thread_id
    remove_column :trm_blue_shifts, :market_problem_comment_thread_id
    remove_column :trm_blue_shifts, :marketing_problem_comment_thread_id
    remove_column :trm_blue_shifts, :capital_problem_comment_thread_id
  end
end
