class AddThreadsToBlueShifts < ActiveRecord::Migration
  class BlueShift < ActiveRecord::Base
    
    belongs_to :people_problem_comment_thread, class_name: "Commontator::Thread", autosave: true
    belongs_to :product_problem_comment_thread, class_name: "Commontator::Thread", autosave: true
    belongs_to :pricing_problem_comment_thread, class_name: "Commontator::Thread", autosave: true
    belongs_to :need_help_comment_thread, class_name: "Commontator::Thread", autosave: true
    
    before_validation :set_comment_threads
  
    private
    def set_comment_threads
      if people_problem == true
        self.people_problem_comment_thread ||= Commontator::Thread.new(commontable_id: self.id, commontable_type: "BlueShift")
      end
      
      if product_problem == true
        self.product_problem_comment_thread ||= Commontator::Thread.new(commontable_id: self.id, commontable_type: "BlueShift")
      end
      
      if pricing_problem == true
        self.pricing_problem_comment_thread ||= Commontator::Thread.new(commontable_id: self.id, commontable_type: "BlueShift")
      end
      
      if need_help == true
        self.need_help_comment_thread ||= Commontator::Thread.new(commontable_id: self.id, commontable_type: "BlueShift")
      end
      
      return true
    end  
  end
  
  
  class Thread < ActiveRecord::Base
    belongs_to :commontable, :polymorphic => true
  end
  
  def up
    # add_reference :blue_shifts, :people_problem_thread, references: :commontator_thread, index: true
    # add_foreign_key :blue_shifts, :commontator_threads, column: :people_problem_thread_id
    
    # add_column :commontator_threads, :attribute_name, :string

    add_reference :blue_shifts, :comment_thread, references: :commontator_thread, index: true
    add_foreign_key :blue_shifts, :commontator_threads, column: :comment_thread_id
    
    add_reference :blue_shifts, :people_problem_comment_thread, references: :commontator_thread, index: true
    add_foreign_key :blue_shifts, :commontator_threads, column: :people_problem_comment_thread_id
    
    add_reference :blue_shifts, :product_problem_comment_thread, references: :commontator_thread, index: true
    add_foreign_key :blue_shifts, :commontator_threads, column: :product_problem_comment_thread_id
    
    add_reference :blue_shifts, :pricing_problem_comment_thread, references: :commontator_thread, index: true
    add_foreign_key :blue_shifts, :commontator_threads, column: :pricing_problem_comment_thread_id
    
    add_reference :blue_shifts, :need_help_comment_thread, references: :commontator_thread, index: true
    add_foreign_key :blue_shifts, :commontator_threads, column: :need_help_comment_thread_id
    
    begin
      remove_index :commontator_threads, name: "index_commontator_threads_on_c_id_and_c_type"
    rescue
    end
    
    execute("UPDATE blue_shifts \
     SET comment_thread_id = (SELECT id FROM commontator_threads WHERE \
     commontable_type='BlueShift' AND commontable_id=blue_shifts.id LIMIT 1)")
     
     
    BlueShift.all.each do |blue_shift|
      blue_shift.updated_at = DateTime.now
      blue_shift.save!    
    end
     
  end
  
  def down
    remove_column :blue_shifts, :comment_thread_id
    remove_column :blue_shifts, :people_problem_comment_thread_id
    remove_column :blue_shifts, :product_problem_comment_thread_id
    remove_column :blue_shifts, :pricing_problem_comment_thread_id
    remove_column :blue_shifts, :need_help_comment_thread_id
  end
  
end
