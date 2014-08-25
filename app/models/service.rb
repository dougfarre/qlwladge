class Service < ActiveRecord::Base
  attr_accessor :custom_domain

  after_initialize :assign_type
  before_validation :name_is_valid_type
  before_save :init

  belongs_to :user
  has_many :definitions

  #validates_uniqueness_of :user_id, :type
  validate :name_is_valid_type

  def name=(value)
    write_attribute(:name, value)
    assign_type
  end

  # Class methods
  def self.new(attributes=nil)
    service = super(attributes)
    service_class = attributes[:name].constantize rescue nil
    service = service.becomes(service_class) if service_class && service.valid?

    return service
  end

  private

  # Validators & callbacks
  def assign_type
    self.type ||= self.name if name_is_valid_type
  end

  def name_is_valid_type
    return true if Service.subclasses.map(&:name).include? self.name
    error_message = ": Service of type '" + self.name.to_s + "' is not supported."

    errors.add(:name, error_message) if self.errors[:name].blank?
    false
  end
end
