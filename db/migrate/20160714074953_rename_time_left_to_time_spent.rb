class RenameTimeLeftToTimeSpent < ActiveRecord::Migration
  def change
  	rename_column :quiz_submission_attempts, :time_left, :time_spent
  end
end
