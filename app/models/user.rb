# require 'digest'
# == Schema Information
#
# Table name: users
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime
#  updated_at :datetime
#
# 
# class User < ActiveRecord::Base
#   attr_accessible :name
#   
#   validates :name,  :presence => true
# #                    :length   => { :minimum => 10 }
# end

class User
  include Mongoid::Document
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  
  field :name
    validates_presence_of :name
  field :email
    validates_uniqueness_of :email, :message => "That login has already beed taken", :case_sensitive => false, :on => :create
    validates_presence_of   :email, :message => "You must have a login ID", :on => :create
  field :password
    validates_presence_of   :password, :message => "You must supply a password", :on => :create

  devise  :database_authenticatable, :registerable, :timeoutable, 
          :recoverable, :rememberable, :trackable, :validatable, :omniauthable
end
