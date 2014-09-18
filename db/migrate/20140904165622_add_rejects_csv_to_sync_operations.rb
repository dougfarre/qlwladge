class AddRejectsCsvToSyncOperations < ActiveRecord::Migration
  def change
    add_column :sync_operations, :rejects_file, :string
  end
end
