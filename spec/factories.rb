# By using the symbol ':user', we get Factory Girl to simulate the User model.
Factory.define :user do |user|
  user.dates           "today"
  user.city          "Boston"
  user.keywords       "testing"
end

Factory.define :result do |result|
  result.name  "Lenny Live At The Paramount"
  result.date_string  "Sunday Aug 24 2011 at 7PM"
  result.venue  "Paramount Theater"
  result.band  "Lenny and the Long Legs"
  result.track_name  "Sweet Home Pennyslyania"
  result.track_spotify  "5qtkWmheqR1COnUvA9UP7r"
  result.details_url  "www.lennylonglegs.com"
  result.association :user
end

Factory.sequence :name do |n|
  "The-#{n} Example Event  "
end
