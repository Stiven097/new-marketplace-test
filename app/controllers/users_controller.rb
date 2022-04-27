class UsersController < ApplicationController
  before_action :authenticate_user!

  def dashboard

  end

  def show
    @user = User.find(params[:id])
    @reviews = Review.where(seller_id: params[:id]).order("created_at desc")
  end

  def update
    @user = current_user
    if @user.update_attributes(current_user_params)
      flash[:notice] = "User details updated"
    else
      flash[:alert] = "Cannot update"
    end
    redirect_to dashboard_path
  end

  def update_payment
    if !current_user.stripe_id
      customer = Stripe::Customer.create(
        email: current_user.email,
        source: params[:stripeToken],
        expand: ['sources']
      )
    else
      customer = Stripe::Customer.update(
        current_user.stripe_id,
        source: params[:stripeToken]
      )
    end

    if current_user.update(stripe_id: customer.id, stripe_last_4: customer.sources.data.first["last4"])
      flash[:notice] = "Card information added successfully"
    else
      flash[:alert] = "Invalid card information"
    end

    redirect_to request.referrer
  rescue Stripe::CardError => e
    flash[:alert] = e.message
    redirect_to request.referrer
  end

  private
  def current_user_params
    params.require(:user).permit(:from, :about, :status, :language, :avatar)
  end
end
