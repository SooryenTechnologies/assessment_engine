class AddScoreFilterInQuizzes < ActiveRecord::Migration
  def change
    add_column :quizzes, :score_filter, :string
  end
end
