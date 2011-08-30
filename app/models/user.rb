# == Schema Information
#
# Table name: users
#
#  id               :integer         not null, primary key
#  name             :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#  maxNumberOfBands :string(255)
#

require 'digest'
class User < ActiveRecord::Base
  attr_accessible :name
  attr_accessible :maxNumberOfBands
  validates :name,  :presence => true
#                    :length   => { :minimum => 10 }
end
