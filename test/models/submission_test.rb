require 'test_helper'

class SubmissionTest < ActiveSupport::TestCase

  def setup
    @submission = Submission.new(url: "http://BUtternutmountainfarm.com/about-maple/recipes/raw-maple-cashew-energy-balls")
  end

  test "should be valid" do
    assert @submission.valid?
  end

  test "url should be present" do
    @submission.url = ''
    assert_not @submission.valid?
  end

  test "url should not be longer than what's supported by most browsers" do
    @submission.url = 'a' * 2049
    assert_not @submission.valid?
  end

  test "url validation should accept valid urls" do
    valid_urls= %w[http://www.example.com WWW.example.COM recipe.example.ORG https://www.example.com/food]
    valid_urls.each do |valid_url|
    @submission.url = valid_url
    assert @submission.valid?, "#{valid_url.inspect} should be valid"
    end
  end

  test "url validation should reject invalid urls" do
    invalid_urls = %w["http://wwwexamplecom" "http:/www.example.com" "http://www example.com"]
    invalid_urls.each do |invalid_url|
      @submission.url = invalid_url
      assert_not @submission.valid?, "#{invalid_url.inspect} should be invalid"
    end
  end

  test "title should be grabbed from html using url" do
    @submission.save
    assert_not_nil @submission.title
  end


end
