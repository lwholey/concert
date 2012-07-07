# By using the symbol ':user', we get Factory Girl to simulate the User model.
Factory.define :user do |user|
  user.start_date "11/4/2011"
  user.end_date   "11/6/2011"
  user.city          "Boston"
  user.keywords       "testing"
end

Factory.define :result do |result|
  result.name  "Lenny Live At The Paramount"
  result.date_string  "Sunday Aug 24 2011 at 7PM"
  result.venue  "Paramount Theater"
  result.band  "Lenny and the Long Legs"
  result.details_url  "www.lennylonglegs.com"
  result.association :user
end

Factory.sequence :name do |n|
  "The-#{n} Example Event  "
end
