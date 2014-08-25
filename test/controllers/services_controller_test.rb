require 'test_helper'

class ServicesControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
    Rails.application.eager_load!
    @user = users(:one)
    sign_in @user
    @service = services(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:services)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create when service is valid" do
    assert_difference('Service.count') do
      post :create, service: {name: 'Marketo', user_id: 100 }
    end

    assert_redirected_to service_path(assigns(:service))
  end
  test "service specific attributes should auto set on create" do
    assert_difference('Service.count') do
      post :create, service: {name: 'Marketo', user_id: 440 }
    end

    service = Service.last

    assert(!service.api_path.blank?)
  end

  test "shouln't create when service is invalid" do
    service_count = Service.count
    post :create, service: {name: 'Chicken', user_id: 100 }
    assert_equal(Service.count, service_count)
  end

  test "should show service" do
    get :show, id: @service
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @service
    assert_response :success
  end

  test "should update service" do
    patch :update, id: @service, service: { application_api_key: 'data.api.com' }
    assert_redirected_to service_path(assigns(:service))
  end

  test "should update api and authorization domains" do
    custom_domain = 'http://data.api.com'
    patch :update, id: @service, service: { custom_domain: custom_domain }
    assert_equal(custom_domain, @service.api_domain)
    assert_equal(custom_domain, @service.authorization_domain)
  end

  test "should destroy service" do
    assert_difference('Service.count', -1) do
      delete :destroy, id: @service
    end

    assert_redirected_to services_path
  end
end
