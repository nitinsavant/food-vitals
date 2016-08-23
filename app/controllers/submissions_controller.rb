class SubmissionsController < ApplicationController
  before_action :find_submission, only: [:show, :edit, :update, :destroy]

  def index
    @submissions = Submission.all.order("created_at DESC")
  end

  def show
    @ingredients = Submission.get_ingredients_from_response(params[:id])
  end

  def new
    @submission = Submission.new
  end

  def create
    params[:spoon_recipe_response] = Submission.get_recipe_from_spoon(params[:url])
    @submission = Submission.new(submission_params)
    if @submission.save
      flash[:success] = "Recipe submitted!"
      redirect_to @submission
    else
      render 'static_pages/home'
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
    params.require(:submission).permit(:url, :spoon_recipe_response)
  end

  def find_submission
    @submission = Submission.find(params[:id])
  end

end
