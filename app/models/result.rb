# == Schema Information
#
# Table name: results
#
#  id            :integer         primary key
#  name          :string(255)
#  date_string   :string(255)
#  venue         :string(255)
#  band          :string(255)
#  details_url   :string(255)
#  created_at    :timestamp
#  updated_at    :timestamp
#  user_id       :integer
#  you_tube_url  :string(255)
#

class Result < ActiveRecord::Base
  belongs_to :user

  validates :user_id, :presence => true

end
