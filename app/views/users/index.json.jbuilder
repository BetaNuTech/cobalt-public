json.array!(@users) do |user|
  json.extract! user, :id, :email, :t1_role, :t2_role, :team_id
  json.url user_url(user, format: :json)
end
