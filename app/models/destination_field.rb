class DestinationField < ActiveRecord::Base
  belongs_to :definition
  has_one :mapping

  validates_uniqueness_of :name, scope: :definition_id
end
