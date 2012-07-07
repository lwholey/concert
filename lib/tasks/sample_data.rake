namespace :db do
  desc "Fill database with sample data"
  task :populate => :environment do
    Rake::Task['db:reset'].invoke

    User.create!(:start_date => "11/4/2011",
                 :end_date => "11/6/2011",
                 :city => "Boston",
                 :keywords => "jazz")

    3.times do |n|
      city = "Boston"
      keywords  = Faker::Name.name
      User.create!(:start_date => "11/4/2011",
                   :end_date => "11/6/2011",
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
          :details_url => "www.lennylonglegs.com"
        )
      end
    end
  end
end
