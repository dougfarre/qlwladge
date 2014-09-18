class RemoveRejectFieldFromSyncOperations < ActiveRecord::Migration
  def change
    remove_column :sync_operations, :has_rejects
    remove_column :sync_operations, :name
  end
end
