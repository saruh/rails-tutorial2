class UsersController < ApplicationController
  before_action :signed_in_user,        only: [:index, :edit, :update, :destroy]
  before_action :correct_user,          only: [:edit, :update]
  before_action :admin_user,            only: :destroy
  before_action :restrict_registration, only: [:new, :create]

  def index
    @users = User.paginate(page: params[:page])
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      sign_in @user
      flash[:success] = "Welcome to the Sample App!"
      redirect_to @user
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    user = User.find(params[:id])
    if current_user?(user)
      flash[:notice] = "Cannot destroy yourself."
    else
      User.find(params[:id]).destroy
      flash[:success] = "User destroyed."
    end
    redirect_to users_url
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password,
                                   :password_confirmation)
    end

# Before actions

    def signed_in_user
      unless signed_in?
        store_location
        #flash[:notice] = "Please sign in."
        #redirect_to signin_url
        redirect_to signin_url, notice: "Please sign in."
      end
    end

    def correct_user
       @user = User.find(params[:id])
       redirect_to(root_path) unless current_user?(@user)
    end

    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end

    def restrict_registration
       redirect_to root_url, notice: "You are already regsitered." if signed_in?
    end
  end