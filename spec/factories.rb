# By using the symbol ':user', we get Factory Girl to simulate the User model.
Factory.define :user do |user|
  user.dates           "today"
  user.city          "Boston"
  user.keywords       "testing"
end
