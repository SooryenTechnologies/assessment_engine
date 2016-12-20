class CreateTemporaryData < ActiveRecord::Migration
  def change
    create_table :temporary_data do |t|
      t.string :data
      t.integer :user_id
      t.integer :submission_attempt_id

      t.timestamps
    end
  end
end
