module Validators
  class DateTodayOrAfterValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      return if value.blank? 
     
      if value < Time.now.to_date and record.send("#{attribute}_changed?")
        record.errors[attribute] << (options[:message] || "must be on or after today")
      end 
    end
  end
end

