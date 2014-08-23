class RemoveTokenPathFromServices < ActiveRecord::Migration
  def change
    remove_column :services, :token_path
  end
end
