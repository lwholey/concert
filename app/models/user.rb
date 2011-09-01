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
#

require 'digest'
class User < ActiveRecord::Base
  attr_accessible :maxNumberOfBands
  attr_accessible :dates
  attr_accessible :city
  attr_accessible :keywords
  attr_accessible :pageNumber

#  validates :name,  :presence => true
#                    :length   => { :minimum => 10 }
end
