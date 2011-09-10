# == Schema Information
#
# Table name: results
#
#  id            :integer         not null, primary key
#  name          :string(255)
#  date_string   :string(255)
#  date_type     :datetime
#  venue         :string(255)
#  band          :string(255)
#  track_name    :string(255)
#  track_spotify :string(255)
#  details_url   :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#  user_id       :integer
#

class Result < ActiveRecord::Base
  belongs_to :user

  validates :user_id, :presence => true

  # order the results so that ones with spotify links are first
  default_scope :order => 'results.track_spotify DESC'
end
