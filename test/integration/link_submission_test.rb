require 'test_helper'

class LinkSubmissionTest < ActionDispatch::IntegrationTest

  test "invalid link submission" do
    get submit_path
    assert_no_difference 'Submission.count' do
      post submit_path, params: { submission: { url: "" } }
    end
    assert_template 'submissions/new'
    end

    test "valid link submission" do
    get submit_path
    assert_difference 'Submission.count', 1 do
      post submit_path, params: { submission: { url: "http://www.example.org" } }
    end
    follow_redirect!
    assert_template 'submissions/show'
  end

end
