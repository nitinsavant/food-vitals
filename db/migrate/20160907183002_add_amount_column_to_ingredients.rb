class AddAmountColumnToIngredients < ActiveRecord::Migration[5.0]
  def change
    add_column :ingredients, :amount, :float
  end
end
