class DropTable < ActiveRecord::Migration
  def change
    drop_table :question_types
  end
end
