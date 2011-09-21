namespace :db do
  desc "Fill database with sample data"
  task :populate => :environment do
    Rake::Task['db:reset'].invoke

    User.create!(:dates => "today",
                 :city => "Boston",
                 :keywords => "jazz")

    3.times do |n|
      dates  = "today"
      city = "Boston"
      keywords  = Faker::Name.name
      User.create!(:dates => dates,
                   :city => city,
                   :keywords => keywords )
    end

    User.all(:limit => 2).each do |user|
      50.times do
        user.results.create!(
          :name => Faker::Lorem.sentence(5),
          :date_string => "Sunday Aug 24, 2011 at 7PM",
          :date_type => "",
          :venue => "Paramount Theater",
          :band => "Lenny and the Long Legs",
          :track_name => "Sweet Home Pennyslyania",
          :track_spotify => "5qtkWmheqR1COnUvA9UP7r",
          :details_url => "www.lennylonglegs.com"
        )
      end
    end
  end
end
