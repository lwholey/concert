# == Schema Information
#
# Table name: users
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

require 'digest'
class User < ActiveRecord::Base
  attr_accessible :name
  
  validates :name,  :presence => true
#                    :length   => { :minimum => 10 }
end
