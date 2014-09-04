class AddChangesToSyncOperations < ActiveRecord::Migration
  def change
    add_column :sync_operations, :has_rejects, :boolean
    add_column :sync_operations, :source_file, :string
    remove_column :sync_operations, :source_data
  end
end
