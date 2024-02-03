# == Schema Information
#
# Table name: employees
#
#  id                        :integer          not null, primary key
#  employee_id               :string
#  first_name                :string
#  last_name                 :string
#  ext_created_at            :datetime
#  ext_person_changed_at     :datetime
#  ext_employment_changed_at :datetime
#  date_in_job               :datetime
#  date_last_worked          :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  date_of_birth             :datetime
#  workable_name             :string
#
class Employee < ActiveRecord::Base
  validates :employee_id, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true

  # Known non-matches:
  # "william osborne" (transfer)
  # "tanishua williams" (transfer)
  # "michael simonetti" (didn't start)
  # "miriah rose" (transfer)
  # "christopher hartgraves" (transfer)
  # "felix quinones" (PROMOTED)
  # "vanessa byes" (transfer)
  # Thomas Owens- PROMOTED
  def map_to_workable_name
    unless self.first_name.nil? || self.last_name.nil?
      full_name = self.first_name + " " + self.last_name

      # Overrides go here
      # Note: all matches and overrides must be in all lowercase
      # case full_name.downcase
      # when "johnny wood"
      #   self.workable_name = "john wood"
      # when "amanda hahn salazar"
      #   self.workable_name = "amanda hahn-salazar, cam"
      # when "thomas owens"
      #   self.workable_name = "thomas s. owens jr"
      # when "miriah spence"
      #   self.workable_name = "miriah rose"
      # else
      #   self.workable_name = full_name.downcase
      # end

      # Now using employee_first_name_override and employee_last_name_override
      self.workable_name = full_name.downcase


      if full_name.downcase != self.workable_name
        puts "#{full_name.downcase} mapped to #{self.workable_name} (override)"
      end
    end
  end

  # def update_date_in_job_for_transfers
  #   unless self.first_name.nil? || self.last_name.nil?
  #     prev_date_in_job = self.date_in_job

  #     # Overrides go here
  #     # Note: all matches and overrides must be in all lowercase
  #     case full_name.downcase
  #     when "william osborne"
  #       self.date_in_job = DateTime.new(2013, 12, 24, 8, 0, 0, ‘-5’)
  #     when "tanishua williams"
  #       self.date_in_job = DateTime.new(2013, 12, 24, 8, 0, 0, ‘-5’)
  #     when "mariah spence"
  #       self.date_in_job = DateTime.new(2013, 12, 24, 8, 0, 0, ‘-5’)
  #     when "christopher hartgraves"
  #       self.date_in_job = DateTime.new(2013, 12, 24, 8, 0, 0, ‘-5’)
  #     when "felix quinones"
  #       self.date_in_job = DateTime.new(2013, 12, 24, 8, 0, 0, ‘-5’)
  #     when "vanessa byes"
  #       self.date_in_job = DateTime.new(2013, 12, 24, 8, 0, 0, ‘-5’)
  #     else
  #       self.date_in_job = self.date_in_job
  #     end

  #     if self.date_in_job != prev_date_in_job
  #       puts "#{full_name.downcase} date_in_job mapped to #{self.date_in_job} (override)"
  #     end
  #   end
  # end

end

