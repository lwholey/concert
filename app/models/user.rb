# == Schema Information
#
# Table name: users
#
#  id         :integer         not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  city       :string(255)
#  keywords   :string(255)
#  pageNumber :integer
#  max_pages  :integer
#  start_date :string(255)
#  end_date   :string(255)
#

require 'digest'
class User < ActiveRecord::Base
#  after_initialize :default_values

  attr_accessible :maxNumberOfBands
  attr_accessible :start_date
  attr_accessible :end_date
  attr_accessible :city
  attr_accessible :keywords
  attr_accessible :pageNumber
  attr_accessible :max_pages

  # ensure results are destroyed along with user
  has_many :results, :dependent => :destroy
  
  has_many :performers
  private

end
