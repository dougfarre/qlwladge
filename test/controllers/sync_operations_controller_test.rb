require 'test_helper'

class SyncOperationsControllerTest < ActionController::TestCase
  setup do
    @sync_operation = sync_operations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sync_operations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create sync_operation" do
    assert_difference('SyncOperation.count') do
      post :create, sync_operation: {  }
    end

    assert_redirected_to sync_operation_path(assigns(:sync_operation))
  end

  test "should show sync_operation" do
    get :show, id: @sync_operation
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @sync_operation
    assert_response :success
  end

  test "should update sync_operation" do
    patch :update, id: @sync_operation, sync_operation: {  }
    assert_redirected_to sync_operation_path(assigns(:sync_operation))
  end

  test "should destroy sync_operation" do
    assert_difference('SyncOperation.count', -1) do
      delete :destroy, id: @sync_operation
    end

    assert_redirected_to sync_operations_path
  end
end
