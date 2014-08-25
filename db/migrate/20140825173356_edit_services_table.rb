class EditServicesTable < ActiveRecord::Migration
  def change
    rename_column :services, :authorization_path, :auth_path
    rename_column :services, :authorization_domain, :auth_domain
    rename_column :services, :application_api_key, :app_api_key
    rename_column :services, :application_api_secret, :app_api_secret
    
    add_column :services, :token_path, :string
  end
end
