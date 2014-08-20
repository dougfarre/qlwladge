class DestinationField < ActiveRecord::Base
  belongs_to :definition
  has_one :mapping
end
