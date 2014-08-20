class Definition < ActiveRecord::Base
  has_many :destination_fields
  belongs_to :service
  belongs_to :user
end
