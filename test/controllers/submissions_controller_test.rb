require 'test_helper'

class SubmissionsControllerTest < ActionDispatch::IntegrationTest

  test "create invalid submission" do
    get root_path
    assert_select "h1", "Food Vitals"
    assert_no_difference 'Submission.count' do
      post submissions_path, params: { submission: { url: "" } }
    end
    assert_select "h1", "Food Vitals"
    assert_match "Error", response.body
  end

  test "create valid submission" do
    get root_path
    url = "http://www.example.org"
    spoon_recipe_response = "<>"
    title = "Example Domain"
    assert_difference 'Submission.count', 1 do
      post submissions_path, params: { submission: { url: url, spoon_recipe_response: spoon_recipe_response } }
    end
  end

  test "delete submission" do
    @submission = Submission.new(url: "http://BUtternutmountainfarm.com/about-maple/recipes/raw-maple-cashew-energy-balls", spoon_recipe_response: "<>")
    @submission.save
    first_submission = Submission.first
    assert_difference 'Submission.count', -1 do
      delete submission_path(first_submission)
    end
  end

end
