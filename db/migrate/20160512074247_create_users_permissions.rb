class CreateUsersPermissions < ActiveRecord::Migration
  def change
    create_table :users_permissions do |t|
      t.integer :client_id
      t.integer :user_id
      t.integer :context_id
      t.string :role
      t.string :permission

      t.timestamps
    end
  end
end
