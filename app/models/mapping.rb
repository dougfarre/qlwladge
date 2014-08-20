class Mapping < ActiveRecord::Base
  belongs_to :definition
  belongs_to :destination_field
end
