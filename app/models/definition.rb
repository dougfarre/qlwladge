class Definition < ActiveRecord::Base
  has_many :fields
  belongs_to :service
  belongs_to :user
end
