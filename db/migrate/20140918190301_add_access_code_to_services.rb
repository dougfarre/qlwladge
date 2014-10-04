class AddAccessCodeToServices < ActiveRecord::Migration
  def change
    add_column :services, :access_code, :text
  end
end
