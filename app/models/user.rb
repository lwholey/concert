# == Schema Information
#
# Table name: users
#
#  id               :integer         not null, primary key
#  created_at       :datetime
#  updated_at       :datetime
#  maxNumberOfBands :string(255)
#  dates            :string(255)
#  city             :string(255)
#  keywords         :string(255)
#

require 'digest'
class User < ActiveRecord::Base
  attr_accessible :maxNumberOfBands
  attr_accessible :dates
  attr_accessible :city
  attr_accessible :keywords

#  validates :name,  :presence => true
#                    :length   => { :minimum => 10 }
end
