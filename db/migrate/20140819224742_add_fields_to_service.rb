class AddFieldsToService < ActiveRecord::Migration
  def change
    add_column :services, :access_token, :text
    add_column :services, :token_type, :string
    add_column :services, :expires_in, :integer
    add_column :services, :refresh_token, :text
  end
end
