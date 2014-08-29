class AddAuthErrorToServices < ActiveRecord::Migration
  def change
    add_column :services, :auth_error, :string
  end
end
