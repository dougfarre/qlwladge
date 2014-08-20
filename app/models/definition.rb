class Definition < ActiveRecord::Base
  has_many :destination_fields
  has_many :sync_operations
  belongs_to :service
  belongs_to :user
end
