class AddMitsFieldsToServices < ActiveRecord::Migration
  def change
    add_column :services, :metrc_username, :string
    add_column :services, :metrc_password, :string
  end
end
