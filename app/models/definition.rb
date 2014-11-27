require 'csv'

class Definition < ActiveRecord::Base
  mount_uploader :source_file, SourceFileUploader, one: :file_name

  serialize :product_groups, Array

  has_many :destination_fields, autosave: true
  has_many :request_parameters, autosave: true
  has_many :mappings, autosave: true
  has_many :sync_operations
  belongs_to :service

  validates_presence_of :description, :mits_facility, :product_groups
  validates_uniqueness_of :description

  after_initialize :build_request_parameters

  def build_request_parameters
    params = JSON.parse self.service.request_parameters rescue raise 'Request parameters not defined.'

    if new_record?
      params = params['parameters']

      params.keys.each do |param_key|
        options = params[param_key]['options']
        options_type = params[param_key]['options_type']
        url = params[param_key]['url']

        if options and options_type == 'array'
          options = options.map{|option| {id: option, name: option}}
        elsif !url.blank? and options_type == 'hash'
          options = self.service.generic_call(url).map{|item|
            { id: item['id'], name: item['name'] }
          }
        elsif !url.blank? and options_type == 'array'
          options = self.service.generic_call(url).map{|item|
            {id: item, name: item}
          }
        else
          options = []
        end

        self.request_parameters.build(
          name: param_key,
          description: params[param_key]['description'],
          default: params[param_key]['default'],
          options: options,
          options_type: options_type,
          url: params[param_key]['url']
        )
      end
    end
  end
end

