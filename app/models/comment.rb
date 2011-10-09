# == Schema Information
#
# Table name: comments
#
#  id         :integer         primary key
#  body       :text
#  created_at :timestamp
#  updated_at :timestamp
#  email      :string(255)
#

class Comment < ActiveRecord::Base
end
