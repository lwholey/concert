# == Schema Information
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  body       :text
#  created_at :datetime
#  updated_at :datetime
#  email      :string(255)
#

class Comment < ActiveRecord::Base
end
