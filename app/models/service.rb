class Service < ActiveRecord::Base
  attr_accessor :custom_domain
  attr_accessor :app_id, :app_secret
  attr_accessor :current_request

  serialize :facilities, Array

  belongs_to :user
  has_many :definitions

  after_initialize :assign_type, if: :doesnt_have_type
  before_validation :name_is_valid_type

  validates_uniqueness_of :user_id, scope: :name
  validate :no_auth_error

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
    raise "object.discovery_address is not defined"
  end

  def api_address
    raise "object.api_address is not defined"
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

  def export_params(mappings, sync_operation)
    {}
  end

  # Class methods

  def self.services
    #subclasses = Service.subclasses.map(&:name)
    #subclasses = ['Eloqua', 'Marketo'] if subclasses.blank?
    #return subclasses
    ['VendHQ']
  end

  #make this hash that describes data type and mapped_to_id
  def self.excluded_meta_attrs
    ['tmp_id', 'assigned_entity_id', 'sync_status', 'sync_details']
  end

  def self.redirect_address(request)
    uri = URI.parse(request.url)
    uri.path = '/oauth2/callback'
    uri.query = nil
    uri.to_s
  end

  def check_required_attributes(attrs)
    blank_attrs = attrs.select{|attr| self.send(attr).blank?}
    error_message = "The following attribute(s) is/are not defined: " + blank_attrs.to_s
    raise error_message unless blank_attrs.blank?
  end

  def is_token_expired
    expires_at = self.updated_at + self.expires_in.seconds
    Time.now > expires_at
  end

  private

  def make_api_call(type, address, data)
    raise "object.get_api_call is not defined"
  end

  # Validators & callbacks
  def assign_type
    self.becomes!(self.name.constantize).init if new_record? && name_is_valid_type
  end

  def name_is_valid_type
    return true if self.class.services.include? self.name
    error_message = ": Service of type '" + self.name.to_s + "' is not supported."

    errors.add(:name, error_message) if self.errors[:name].blank?
    false
  end

  def doesnt_have_type
    self.type.blank?
  end

  def no_auth_error
    return true if self.auth_error.blank?
    errors.add(:base, self.auth_error) and return false
  end

  def load_parameters_file
    path = Rails.root.to_s + 
      '/app/models/services/' +
      self.name.downcase +
      '_parameters.yml'

    YAML.load_file(path)
  end
end
