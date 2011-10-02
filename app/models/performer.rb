# == Schema Information
#
# Table name: performers
#
#  id           :integer         not null, primary key
#  performer    :string(255)
#  you_tube_url :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#

class Performer < ActiveRecord::Base
end
