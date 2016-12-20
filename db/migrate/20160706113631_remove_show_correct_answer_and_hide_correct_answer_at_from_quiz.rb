class RemoveShowCorrectAnswerAndHideCorrectAnswerAtFromQuiz < ActiveRecord::Migration
  def change
  	 remove_column :quizzes, :show_correct_answers_at
  	  remove_column :quizzes, :hide_correct_answers_at
  end
end
