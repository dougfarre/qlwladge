require 'test_helper'

class ServiceTest < ActiveSupport::TestCase
  def setup
    Rails.application.eager_load!
    @user = User.create(email: 'test@spiceworks.com', password: 'test', password_confirmation: 'test')
    @user_two = User.create(email: 'test@spiceworks.com', password: 'test', password_confirmation: 'test')
  end

  def teardown
    @user.destroy
    @user_two.destroy
  end

  test "Service object should return validation error when name attribute is not a Service subclass" do
    service = Service.create(name: 'Chicken', user_id: @user.id)
    assert !service.errors[:name].blank?
  end

  test "name attribute must equal a Service subclass" do
    service = Service.create(name: 'Eloqua', user_id: @user.id)
    assert service.errors[:name].blank?
  end

  test "name attribute must equal a Service subclass 2" do
    service = Service.new(name: 'Marketo', user_id: @user.id)
    assert service.errors[:name].blank?
  end

  test "service type is assigned based on name attribute and on new" do
    service = Service.new(name: 'Marketo', user_id: @user_two.id)
    assert service.type == 'Marketo'
  end

end
