require 'httparty'

class SparkleApi
  include HTTParty
  base_uri 'https://us-central1-sapphire-inspections.cloudfunctions.net'

  def initialize(property_code)
    @options = { query: { cobalt_code: property_code } }
  end

  def latestCompleteInspection
    self.class.get("/latestCompleteInspection", @options)
  end

end