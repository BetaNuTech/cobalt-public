User.create!(email: "admin@example.com", password: "password", t1_role: "admin", first_name: "Homer", last_name: "Simpson")
User.create!(email: "corporate@example.com", password: "password", t1_role: "corporate", first_name: "Bart", last_name: "Simpson")
property = Property.find_by_code("paddock")
User.create!(email: "property_manager@example.com", password: "password", 
  t1_role: "property", t2_role: "property_manager", first_name: "Lisa", last_name: "Simpson",
  property_ids: [ property.id])
User.create!(email: "maint_super@example.com", password: "password", 
  t1_role: "property", t2_role: "maint_super", first_name: "Marge", last_name: "Simpson",
  property_ids: [ property.id])
User.create!(email: "corp_property_manager@example.com", password: "password", 
  t1_role: "corporate", t2_role: "property_manager", first_name: "Bob", last_name: "Simpson",
  property_ids: [ property.id])
User.create!(email: "corp_maint_super@example.com", password: "password", 
  t1_role: "corporate", t2_role: "maint_super", first_name: "Joe", last_name: "Simpson",
  property_ids: [ property.id])
