class BluebotRollupReportForm
  include ActiveModel::Model
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  attr_accessor :end_month
end
