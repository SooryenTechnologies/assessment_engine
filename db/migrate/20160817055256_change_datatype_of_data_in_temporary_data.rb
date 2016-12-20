class ChangeDatatypeOfDataInTemporaryData < ActiveRecord::Migration
  def change
    change_column :temporary_data, :data, :text
  end
end
