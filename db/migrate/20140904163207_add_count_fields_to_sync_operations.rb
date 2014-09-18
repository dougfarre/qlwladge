class AddCountFieldsToSyncOperations < ActiveRecord::Migration
  def change
    add_column :sync_operations, :record_count, :integer
    add_column :sync_operations, :success_count, :integer
    add_column :sync_operations, :reject_count, :integer
  end
end
