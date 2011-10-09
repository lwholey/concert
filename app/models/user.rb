# == Schema Information
#
# Table name: users
#
#  id         :integer         primary key
#  created_at :timestamp
#  updated_at :timestamp
#  city       :string(255)
#  keywords   :string(255)
#  pageNumber :integer
#  max_pages  :integer
#  start_date :string(255)
#  end_date   :string(255)
#  sort_by    :string(255)
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
  attr_accessible :sort_by

  # ensure results are destroyed along with user
  has_many :results, :dependent => :destroy
  
  has_many :performers
  private

end
