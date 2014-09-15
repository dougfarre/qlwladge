class Service < ActiveRecord::Base
  attr_accessor :custom_domain
  attr_accessor :custom_client_id, :custom_client_secret

  belongs_to :user
  has_many :definitions

  after_initialize :assign_type
  before_validation :name_is_valid_type
  #before_save :init

  validates_uniqueness_of :user_id, scope: :name
  validates_presence_of :discover_path, :lead_path, :request_parameters
  validate :name_is_valid_type

  def name=(value)
    write_attribute(:name, value)
    assign_type
  end

  def authenticate
    raise "object.authenticate is not defined"
  end

  def authorization_status
    raise "object.authorization_status is not defined"
  end

  def lead_address
    raise "object.lead_address is not defined"
  end

  def discovery_address
    raise "object.authorization_status is not defined"
  end

  def get_discovery
    raise "Service.get_discovery is not defined"
  end

  def sync
    raise "Service.sync is not defined"
  end
  
  def map_data(mappings, source_data)
    raise "Service.build_data_map is not defined"
  end

  # Class methods

  def self.services
    #subclasses = Service.subclasses.map(&:name)
    #subclasses = ['Eloqua', 'Marketo'] if subclasses.blank?
    #return subclasses
    ['Eloqua', 'Marketo']
  end

  #make this hash that describes data type and mapped_to_id
  def self.excluded_meta_attrs
    ['tmp_id', 'assigned_entity_id', 'sync_status', 'sync_details']
  end

  private

  def make_api_call(type, address, data)
    raise "object.get_api_call is not defined"
  end

  # Validators & callbacks
  def assign_type
    if name_is_valid_type
      self.type ||= self.name
      self.becomes(self.type.constantize).init if new_record?
    end
  end

  def name_is_valid_type
    return true if self.class.services.include? self.name
    error_message = ": Service of type '" + self.name.to_s + "' is not supported."

    errors.add(:name, error_message) if self.errors[:name].blank?
    false
  end

  def load_parameters_file
    path = Rails.root.to_s + 
      '/app/models/services/' +
      self.name.downcase +
      '_parameters.yml'

    YAML.load_file(path)
  end
end
