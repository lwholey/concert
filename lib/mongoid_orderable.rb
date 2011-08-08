module Mongoid
  module Orderable
    extend ActiveSupport::Concern
    included do
      field :orderable_default,   :type => Boolean, :default => false
      field :orderable_position,  :type => Integer, :default => 0
    end  
  end
end
