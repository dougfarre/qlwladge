class ChangeOauthTokenToAuthToken < ActiveRecord::Migration
  def change
    rename_column :services, :oauth_token, :auth_token
  end
end
