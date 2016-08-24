class AddIndexToSubmissionsUrl < ActiveRecord::Migration[5.0]
  def change
    add_index :submissions, :url, unique: true
  end
end
