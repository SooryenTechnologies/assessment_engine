class AddResourceLinkIdInQuiz < ActiveRecord::Migration
  def change
    add_column :quizzes, :resource_link_id, :string, after: :context_id
  end
end
