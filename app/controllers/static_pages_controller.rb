class StaticPagesController < ApplicationController
  def home
    @submission = Submission.new
  end

  def help
  end
end
