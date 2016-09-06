require 'test_helper'

class IngredientTest < ActiveSupport::TestCase

  def setup
    @submission = submissions(:fudgy)
    @ingredient = @submission.ingredients.build(name: "Sugar", food_id: 100)
  end

  test "should be valid" do
    assert @ingredient.valid?
  end

  test "submission id should be present" do
    @ingredient.submission_id = nil
    assert_not @ingredient.valid?
  end

  test "name should be present" do
    @ingredient.name = "   "
    assert_not @ingredient.valid?
  end

  test "food_id should be present" do
    @ingredient.food_id = "   "
    assert_not @ingredient.valid?
  end

end
