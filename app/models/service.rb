class Service < ActiveRecord::Base
  belongs_to :user
  has_many :definitions
  validates_uniqueness_of :user_id, :type
end
