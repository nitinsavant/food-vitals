require 'test_helper'

class SubmissionsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @submission = Submission.new(url: "http://butternutmountainfarm.com/about-maple/recipes/raw-maple-cashew-energy-balls")
  end

  # test "ingredient list is displayed on show submission page" do
  #   get submission_path(@submission[:id])
  #   assert_template 'submissions/show'
  # end
end
