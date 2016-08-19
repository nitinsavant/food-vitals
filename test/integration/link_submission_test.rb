require 'test_helper'

class LinkSubmissionTest < ActionDispatch::IntegrationTest

  test "invalid link submission" do
    get root_path
    assert_select "h1", "Food Vitals"
    assert_no_difference 'Submission.count' do
      post submissions_path, params: { submission: { url: "" } }
    end
    assert_select "h1", "Food Vitals"
    assert_match "Error", response.body
  end

  test "valid link submission" do
    get root_path
    assert_difference 'Submission.count', 1 do
      post submissions_path, params: { submission: { url: "http://www.example.org" } }
    end
    follow_redirect!
    assert_template 'submissions/show'
  end

end
