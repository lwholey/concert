# == Schema Information
#
# Table name: users
#
#  id         :integer         not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  dates      :string(255)
#  city       :string(255)
#  keywords   :string(255)
#

require 'spec_helper'

describe User do
  #pending "add some examples to (or delete) #{__FILE__}"
  
  before(:each) do
    @attr = { :dates => "today", 
              :city => "Boston",
              :keywords => "jazz",
            }
  end
  
  it "should create a new instance given valid attributes" do
    User.create!(@attr)
  end
 

  it "should require a search criteria" do
    no_field_user = User.new(@attr.merge(:dates => "", :city => "", :keywords => "Red Rocks"))
    no_field_user.should_not be_valid
  end

end
