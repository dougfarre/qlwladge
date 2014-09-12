class AddSiteNameToServices < ActiveRecord::Migration
  def change
    add_column :services, :site_name, :string
  end
end
