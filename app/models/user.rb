# == Schema Information
#
# Table name: users
#
#  id         :integer         not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  dates      :string(255)
#  city       :string(255)
#  keywords   :string(255)
#

require 'digest'
class User < ActiveRecord::Base
  attr_accessible :maxNumberOfBands
  attr_accessible :dates
  attr_accessible :city
  attr_accessible :keywords

  #validates :city, :presence => true

  validate :must_fill_in_city_or_date_field

  def must_fill_in_city_or_date_field
    if dates.blank? and city.blank? 
      errors.add(:user, "must enter a city or date")
    end
  end
end
