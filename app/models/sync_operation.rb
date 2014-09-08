require 'csv'

class SyncOperation < ActiveRecord::Base
  mount_uploader :source_file, SourceFileUploader, one: :file_name

  serialize :source_data, Array
  serialize :request, Hash
  serialize :response, Hash
  belongs_to :definition

  validates_presence_of :source_file

  before_save :process_source

  def process_source
    return unless new_record?
    options = {
      headers: true,
      header_converters: :symbol,
      converters: :all
    }

    self.source_data = CSV.parse(self.source_file.read, options)
      .collect { |row| Hash[row.collect { |c,r| [c,r] }].merge(row_number: $.) }
    self.record_count = self.source_data.count
  end

  def sample_records
    records = CSV.parse(self.source_file.read)
    count = 1
    sample_records = []

    while count < 6 and !records[count].blank?
      sample_records << records[count].join(';')
      count += 1
    end

    sample_records
  end

  def sync
    self.update_attributes(self.definition.service.sync(self.definition, self))
  end
end
