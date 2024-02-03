FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'Foobar123' }
    password_confirmation { 'Foobar123' }
    first_name   { Faker::Name.first_name }
    last_name   { Faker::Name.last_name }
    t1_role { 'property' }

    factory :admin_user do
      t1_role { 'admin' }
    end
  end
end
