class AddRecievedUserIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :recieved_user_id, :string
  end
end
