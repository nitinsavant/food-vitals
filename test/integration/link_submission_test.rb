require 'test_helper'

class LinkSubmissionTest < ActionDispatch::IntegrationTest

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
    title = "Example Domain"
    assert_difference 'Submission.count', 1 do
      post submissions_path, params: { submission: { url: url } }
    end
    follow_redirect!
    assert_template 'submissions/show'
    assert_match url, response.body
    assert_match title, response.body
    # delete submission
    first_submission = Submission.first
    assert_difference 'Submission.count', -1 do
      delete submission_path(first_submission)
    end
  end

end
