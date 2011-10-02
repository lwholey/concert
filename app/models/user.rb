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
#  pageNumber :integer
#  max_pages  :integer
#

require 'digest'
class User < ActiveRecord::Base
#  after_initialize :default_values

  attr_accessible :maxNumberOfBands
  attr_accessible :dates
  attr_accessible :city
  attr_accessible :keywords
  attr_accessible :pageNumber
  attr_accessible :max_pages

  # ensure results are destroyed along with user
  has_many :results, :dependent => :destroy
  
  has_many :performers
  private
=begin
  def default_values
    if self.city.blank? then self.city = "usa" end
    if self.dates.blank? then self.dates = "future" end
    if self.keywords.blank? then self.keywords = UsersHelper.DEFAULT_KEYWORDS end
  end
=end

  #validates :city, :presence => true

=begin
  validate :must_fill_in_city_or_date_field

  def must_fill_in_city_or_date_field
    if dates.blank? and city.blank? 
      errors.add(:user, "must enter a city or date")
    end
  end
=end

end
