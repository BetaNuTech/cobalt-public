class Job
  def self.create(command, options={})
    Delayed::Job.enqueue command, options   
  end
  
  def self.count
    Delayed::Job.count
  end
end
