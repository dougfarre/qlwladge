class Service < ActiveRecord::Base
  attr_accessor :custom_domain
  after_initialize :assign_type, if: :new_record?
  belongs_to :user
  has_many :definitions
  validates_uniqueness_of :user_id, :type
  validates_presence_of :name
  validate :check_name_values

  private

  # Validators & callbacks
  def check_name_values
    unless Service.subclasses.map(&:name).include? self.name
      errors.add(:name, "Service of type " + self.name + " is not supported.")
    end
  end

  def assign_type
    self.type = self.name
  end
end
