require 'test_helper'

class ServiceTest < ActiveSupport::TestCase
  def setup
    Rails.application.eager_load!
    @user = users(:one)
    @user_two = users(:two)
  end

  def teardown
    @user.destroy
    @user_two.destroy
  end

  test "should return validation error when name attribute is not a Service subclass" do
    service = Service.new(name: 'Chicken', user_id: @user.id)
    assert !service.errors[:name].blank?
  end

  test "name attribute must equal a Service subclass" do
    service = Service.new(name: 'Eloqua', user_id: @user.id)
    assert service.errors[:name].blank?
  end

  test "service type is assigned based on name attribute and on after_initialize" do
    service = Service.new(name: 'Marketo', user_id: @user_two.id)
    assert service.type == 'Marketo'
  end
end
