class SubmissionsController < ApplicationController
  before_action :find_submission, only: [:show, :edit, :update, :destroy]

  def index
    @submissions = Submission.all.order("created_at DESC")
  end

  def show
  end

  def new
    @submission = Submission.new
  end

  def create
    @submission = Submission.new(submission_params)
    if @submission.save
      redirect_to @submission
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @submission.update(submission_params)
      redirect_to @submission
    else
      render 'edit'
    end
  end

  def destroy
    @submission.destroy
    redirect_to submissions_path
  end

  private

  def submission_params
    params.require(:submission).permit(:url)
  end

  def find_submission
    @submission = Submission.find(params[:id])
  end

end