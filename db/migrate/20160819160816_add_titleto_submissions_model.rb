class AddTitletoSubmissionsModel < ActiveRecord::Migration[5.0]
  def change
    add_column :submissions, :title, :string
  end
end
