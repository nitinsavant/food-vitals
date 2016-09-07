class RemoveAmountColumnFromSubmissions < ActiveRecord::Migration[5.0]
  def change
    remove_column :submissions, :amount, :float
  end
end
