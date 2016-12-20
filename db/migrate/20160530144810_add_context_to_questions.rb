class AddContextToQuestions < ActiveRecord::Migration
  def change
    add_reference :questions, :context, index: true
  end
end
