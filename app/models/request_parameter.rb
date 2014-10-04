class RequestParameter < ActiveRecord::Base
  belongs_to :definition
  serialize :options, Array 
end
