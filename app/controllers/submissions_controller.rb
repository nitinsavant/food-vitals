class SubmissionsController < ApplicationController
  before_action :find_submission, only: [:show, :edit, :update, :destroy]

  def index
    @submissions = Submission.all.order("created_at DESC")
  end

  def show
    @submission = Submission.find(params[:id])
    @ingredients = @submission.ingredients.all.inspect
    @nutrition_facts, @nutrition_overview, @xml_response,
      @oauth_params_foodget = Submission.calculate_nutrition(@submission.id)
  end

  def new
    @submission = Submission.new
  end

  def create
    @submission = Submission.new(submission_params)
    if @submission.save
      @ingredient_amounts, @oauth_check, @food_id_array = Submission.get_fatsecret_food_ids(@submission.id)
      if @food_id_array.empty?
        flash[:alert] = 'Sorry! I\'m unable to extract ingredients from that recipe website.'
      else
        redirect_to @submission
      end
    elsif @submission.errors.messages[:url] == "has already been taken"
      @original_submission = Submission.find_by(url: submission_params[:url])
      redirect_to @original_submission
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
    redirect_to root_url
  end

  private

  def submission_params
    params.require(:submission).permit(:url, :spoon_recipe_response)
  end

  def find_submission
    @submission = Submission.find(params[:id])
  end

end
