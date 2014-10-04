class AddFacilitiesToServices < ActiveRecord::Migration
  def change
    add_column :services, :facilities, :text
  end
end
