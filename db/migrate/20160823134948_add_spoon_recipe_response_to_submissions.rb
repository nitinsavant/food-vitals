class AddSpoonRecipeResponseToSubmissions < ActiveRecord::Migration[5.0]
  def change
    add_column :submissions, :spoon_recipe_response, :text
  end
end
