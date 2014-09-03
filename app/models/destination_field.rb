class DestinationField < ActiveRecord::Base
  belongs_to :definition
  has_one :mapping

  validates_uniqueness_of :name, scope: :definition_id

  def is_qualified
    return false if self.is_read_only == true
    return true
  end
end
