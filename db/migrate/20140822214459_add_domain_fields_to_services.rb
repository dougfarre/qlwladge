class AddDomainFieldsToServices < ActiveRecord::Migration
  def change
    add_column :services, :api_domain, :string
    add_column :services, :authorization_domain, :string
    add_column :services, :application_api_key, :string
    add_column :services, :application_api_secret, :string
  end
end
