class AddFieldsToServices < ActiveRecord::Migration
  def change
    add_column :services, :name, :string
    add_column :services, :auth_type, :string
    add_column :services, :authorization_path, :string
    add_column :services, :token_path, :string
  end
end
