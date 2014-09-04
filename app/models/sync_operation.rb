require 'csv'

class SyncOperation < ActiveRecord::Base
  mount_uploader :source_file, SourceFileUploader, one: :file_name

  belongs_to :definition

  validates_presence_of :source_file
end
