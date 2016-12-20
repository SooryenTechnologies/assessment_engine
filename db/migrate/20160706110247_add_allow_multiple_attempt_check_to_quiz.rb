class AddAllowMultipleAttemptCheckToQuiz < ActiveRecord::Migration
  def change
  	add_column :quizzes, :allow_multiple_attempt_check, :boolean
  end
end
