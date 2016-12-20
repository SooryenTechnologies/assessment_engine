class AddTimeleftToQuizSubmissionAttempts < ActiveRecord::Migration
  def change
    add_column :quiz_submission_attempts, :time_left, :decimal
  end
end
