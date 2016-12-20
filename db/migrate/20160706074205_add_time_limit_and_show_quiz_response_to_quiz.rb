class AddTimeLimitAndShowQuizResponseToQuiz < ActiveRecord::Migration
  def change
  	add_column :quizzes, :time_limit_check, :boolean
  	add_column :quizzes, :show_quiz_response, :boolean
  end
end
