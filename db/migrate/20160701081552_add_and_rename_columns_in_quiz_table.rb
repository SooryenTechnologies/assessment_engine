class AddAndRenameColumnsInQuizTable < ActiveRecord::Migration
  def change
    add_column :quizzes, :show_correct_answers_at_date, :date, after: :show_correct_answers_at
    add_column :quizzes, :show_correct_answers_at_time, :time, after: :show_correct_answers_at_date
    add_column :quizzes, :hide_correct_answers_at_date, :date, after: :show_correct_answers_at_time
    add_column :quizzes, :hide_correct_answers_at_time, :time, after: :hide_correct_answers_at_date
  end
end
