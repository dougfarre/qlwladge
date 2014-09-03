require 'csv'

class Definition < ActiveRecord::Base
  mount_uploader :source_file, SourceFileUploader, one: :file_name
  
  has_many :destination_fields, autosave: true
  has_many :request_parameters, autosave: true
  has_many :mappings, autosave: true
  has_many :sync_operations
  belongs_to :service

  after_initialize :build_request_parameters
  validates_presence_of :description, :source_file
  validates_uniqueness_of :description

  def build_request_parameters
    params = JSON.parse self.service.request_parameters rescue raise 'Request parameters not defined.'

    if new_record?
      params = params['parameters']

      params.keys.each do |param_key|
        self.request_parameters.build(
          name: param_key,
          description: params[param_key]['description'],
          optional: params[param_key]['optional'],
          value: params[param_key]['default_value']
        )
      end
    end
  end

  def get_headers
    CSV.parse(self.source_file.read)[0]
  end
end

