load "lib/mongoid_orderable.rb"

class Website
  include Mongoid::Document
  include Mongoid::Orderable
  
  field :label
  field :url
  field :location
  validates_presence_of :url, :message => "You must include the website's URL"
end