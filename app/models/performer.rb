# == Schema Information
#
# Table name: performers
#
#  id           :integer         primary key
#  performer    :string(255)
#  you_tube_url :string(255)
#  created_at   :timestamp
#  updated_at   :timestamp
#

class Performer < ActiveRecord::Base
end
