# == Schema Information
#
# Table name: searches
#
#  id                 :integer         not null, primary key
#  form_location      :string(255)
#  form_musiccategory :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#
class Search < ActiveRecord::Base
  attr_accessible :form_location, :form_musiccategory

  # need validations on these input fields?
  #
end
