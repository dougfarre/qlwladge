class Definition < ActiveRecord::Base
  has_many :destination_fields
  has_many :sync_operations
  has_many :parameters
  belongs_to :service
  belongs_to :user
end
