class AddAuthUserIdToServices < ActiveRecord::Migration
  def change
    add_column :services, :auth_user, :string
  end
end
