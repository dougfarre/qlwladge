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
    additional_attributes = {status: 'new', assigned_entity_id: ''}
    options = {
      headers: true,
      header_converters: :symbol,
      converters: :all
    }

    self.source_data = CSV.parse(self.source_file.read, options)
      .collect { |row| Hash[row.collect { |c,r| [c,r.to_s] }].merge(additional_attributes)}
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

  # return true/false
  def sync
    sync_results = self.definition.service.sync(self.definition, self)
    return false unless sync_results
    crud_results = sync_results[:response]['result']
    raise 'Record count mismatch.' if crud_results.count != self.source_data.count

    self.source_data = self.source_data.map.with_index do |row, i|
      row[:assigned_entity_id] = crud_results[i]['id'].to_s unless crud_results[i]['id'].blank?
      row[:status] = crud_results[i]['status'] unless !crud_results[i]['status'].blank?
      row
    end

    self.update_attributes(sync_results) && self.save if sync_results
  end

  def change_source_data(old_mapped_row, new_mapped_row)
    return false if old_mapped_row.blank? or new_mapped_row.blank?
    update_made = false

    source_data = self.source_data.map do |source_row|
      next source_row if update_made
      new_source_row = source_row_equal_to_mapped_row(source_row, old_mapped_row, new_mapped_row)
      update_made = true if new_source_row
      new_source_row or source_row
    end

    self.update_column(:source_data, source_data)
  end

  def source_row_equal_to_mapped_row(source_row, old_mapped_row, new_mapped_row)
    valid_mappings = self.definition.mappings.map{|mapping|
      mapping if mapping.destination_field
    }.compact!

    !old_mapped_row.keys.each { |destination_field_key|
      mapping = valid_mappings.detect{ |current_mapping|
        current_mapping.destination_field.name == destination_field_key.to_s
      }

      header_key = mapping.source_header.parameterize.downcase.underscore.to_sym
      values_equal = source_row[header_key].to_s == old_mapped_row[destination_field_key].to_s
      return unless values_equal
      source_row[header_key] = new_mapped_row[destination_field_key]
    }

    source_row
  end
end
