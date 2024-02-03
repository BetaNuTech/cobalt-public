json.array!(@properties) do |property|
  json.extract! property, :id
  json.url property_url(property, format: :json)
end
