class ChageTokenNamesAgain < ActiveRecord::Migration
  def change
    rename_column :services, :auth_token, :access_token
    add_column :services, :scope, :string
  end
end
