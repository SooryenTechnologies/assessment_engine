class AddOnceAfterEachAttemptInQuizzes < ActiveRecord::Migration
  def change
    add_column :quizzes, :once_after_each_attempt, :boolean
    add_column :quizzes, :auto_publish, :boolean
    add_column :quizzes, :lock_question_after_answer, :boolean
  end
end
