class RenameAccessTokenToOauthToken < ActiveRecord::Migration
  def change
    rename_column :services, :access_token, :oauth_token
    add_column :services, :api_path, :string
  end
end
