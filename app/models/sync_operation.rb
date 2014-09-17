require 'csv'

class SyncOperation < ActiveRecord::Base
  mount_uploader :source_file, SourceFileUploader, one: :file_name

  attr_accessor :copied_from

  serialize :source_data, Array
  serialize :mapped_data, Array
  serialize :request, Hash
  serialize :response, Hash
  belongs_to :definition

  validates_presence_of :source_file
  validates_presence_of :unique_header

  before_validation :set_unique_header
  before_save :process

  # return true/false
  def sync
    sync_results = self.definition.service.sync(self.definition, self)
    return false unless sync_results
    crud_results = sync_results[:response]['result']
    raise 'Record count mismatch.' if crud_results.count != self.mapped_data.count

    self.update_attributes(sync_results.merge({
      mapped_data: self.mapped_data.map.with_index{ |row, i|
        row['assigned_entity_id'] = crud_results[i]['id'].to_s unless crud_results[i]['id'].blank?
        row['sync_status'] = crud_results[i]['status'] unless crud_results[i]['status'].blank?
        row['sync_details'] = crud_results[i]['reasons'].map{|r| r['message']}.join(', ') unless crud_results[i]['reasons'].blank?
        row
    }}))
  end

  def update_mapped_data(old_row, new_row)
    return false if old_row.blank? or new_row.blank?
    update_made = false

    self.update_column(:mapped_data, self.mapped_data.map{ |current_row|
      next current_row if update_made
      replacement_row = build_replacement_row(current_row, old_row, new_row)
      update_made = true if replacement_row
      replacement_row or current_row
    })
  end

  private

  def build_replacement_row(current_row, old_row, new_row)
    old_row.keys.each { |key|
      next if Service.excluded_meta_attrs.include? key
      return unless current_row[key].to_s == old_row[key].to_s
      current_row[key] = new_row[key]
    }
    current_row
  end

  def process
    return unless new_record?
    process_from_mapped and return unless self.mapped_data.blank?
    process_from_source
  end

  def process_from_source
    options = {
      headers: true,
      header_converters: :symbol,
      converters: :all
    }

    definition = self.definition
    self.source_data = CSV.parse(self.source_file.read, options).map{|row| Hash[row.map{|c,r| [c,r.to_s]}]}
    self.record_count = self.source_data.count
    self.mapped_data = definition.service.map_data(definition.mappings, self.source_data)
  end

  def process_from_mapped
    self.record_count = self.mapped_data.count
    self.mapped_data.each{|m| m['sync_status'] = 'copied'}
  end

  def set_unique_header
    return unless new_record?
    self.unique_header = self.definition.mappings.detect{|mapping|
      !mapping.destination_field.blank? and !mapping.source_key
    }.destination_field.name rescue nil
  end
end
