class AddAmountColumnToSubmissions < ActiveRecord::Migration[5.0]
  def change
    add_column :submissions, :amount, :float
  end
end
