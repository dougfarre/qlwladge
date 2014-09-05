require 'csv'

class SyncOperation < ActiveRecord::Base
  mount_uploader :source_file, SourceFileUploader, one: :file_name

  serialize :source_data, Array
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
    count = 0
    sample_records = []

    while count < 5 and !records[count].blank?
      count += 1
      sample_records << records[count].join(';')
    end

    sample_records
  end

  def sync 
    self.assign_attributes(self.definition.service.sync(self.definition, self))
    binding.pry
    self.valid?
  end
end
