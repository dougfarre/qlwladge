class AddRequestToSyncOperations < ActiveRecord::Migration
  def change
    add_column :sync_operations, :request, :text
  end
end
