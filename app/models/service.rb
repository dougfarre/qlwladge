class Service < ActiveRecord::Base
  attr_accessor :custom_domain
  attr_accessor :custom_client_id, :custom_client_secret

  belongs_to :user
  has_many :definitions

  after_initialize :assign_type
  before_validation :name_is_valid_type
  before_save :init

  validates_uniqueness_of :user_id, scope: :name
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

  # Class methods
  def self.services
    #subclasses = Service.subclasses.map(&:name)
    #subclasses = ['Eloqua', 'Marketo'] if subclasses.blank?
    #return subclasses
    ['Eloqua', 'Marketo']
  end

  private

  # Validators & callbacks
  def assign_type
    self.type ||= self.name if name_is_valid_type
  end

  def name_is_valid_type
    return true if self.class.services.include? self.name
    error_message = ": Service of type '" + self.name.to_s + "' is not supported."

    errors.add(:name, error_message) if self.errors[:name].blank?
    false
  end
end
