class CreateDefinitions < ActiveRecord::Migration
  def change
    create_table :definitions do |t|
      t.integer :service_id
      t.integer :user_id
      t.string :type

      t.timestamps
    end
  end
end
