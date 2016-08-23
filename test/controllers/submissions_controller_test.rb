require 'test_helper'

class SubmissionsControllerTest < ActionDispatch::IntegrationTest

  test "link submission" do
    get root_path
    assert_select "h1", "Food Vitals"
    # invalid submission
    assert_no_difference 'Submission.count' do
      post submissions_path, params: { submission: { url: "" } }
    end
    assert_select "h1", "Food Vitals"
    assert_match "Error", response.body
    # valid submission
    url = "http://www.example.org"
    spoon_recipe_response = "<>"
    title = "Example Domain"
    assert_difference 'Submission.count', 1 do
      post submissions_path, params: { submission: { url: url, spoon_recipe_response: spoon_recipe_response} }
    end
    # delete submission
    first_submission = Submission.first
    assert_difference 'Submission.count', -1 do
      delete submission_path(first_submission)
    end
  end

  test "spoonacular recipe API response stored in database" do
    url = "http://butternutmountainfarm.com/about-maple/recipes/raw-maple-cashew-energy-balls"
    spoon_recipe_response = Submission.get_recipe_from_spoon(url)
    @submission = Submission.new( { url: url, spoon_recipe_response: spoon_recipe_response} )
    @submission.valid?
  end

end
