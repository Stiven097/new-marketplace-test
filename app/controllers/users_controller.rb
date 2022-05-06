class UsersController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    @subscription = Subscription.find_by_user_id(current_user.id)
    if @subscription.present?
      @plan = Stripe::Plan.retrieve(@subscription.plan_id)
    end
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

  def update_payout
    if current_user.update(paypal: params[:paypal])
      flash[:notice] = "Payout information updated successfully"
    else
      flash[:alert] = "Something went wrong"
    end
    redirect_to request.referrer
  end

  def earnings
    @net_income = (Transaction.where("seller_id = ?", current_user.id).sum(:amount) / 1.1).round(2)

    @withdrawn = Transaction.where("buyer_id = ? AND status = ? AND transaction_type = ?", 
                    current_user.id, 
                    Transaction.statuses[:approved],
                    Transaction.transaction_types[:withdraw]
                  ).sum(:amount)

    @pending = Transaction.where("buyer_id = ? AND status = ? AND transaction_type = ?", 
                    current_user.id, 
                    Transaction.statuses[:pending],
                    Transaction.transaction_types[:withdraw]
                  ).sum(:amount)

    @purchased = Transaction.where("buyer_id = ? AND source = ? AND transaction_type = ?", 
                    current_user.id, 
                    Transaction.sources[:system],
                    Transaction.transaction_types[:trans]
                  ).sum(:amount)

    @withdrawable = current_user.wallet

    @transactions = Transaction.where("seller_id = ? OR (buyer_id = ? AND source = ?)", 
                      current_user.id,
                      current_user.id,
                      Transaction.sources[:system]
                ).page(params[:page])

  end

  def withdraw
    amount = params[:amount].to_i
    is_pending_withdraw = Transaction.exists?(buyer_id: current_user.id,
                                              status: Transaction.statuses[:pending],
                                              transaction_type: Transaction.transaction_types[:withdraw])
    
    if amount <= 0
      flash[:alert] = "Invalid amount"
    elsif amount > current_user.wallet
      flash[:alert] = "The requested amount is more than what you have in your wallet"
    elsif !is_pending_withdraw.blank?
      flash[:alert] = "You currently have a pending withdraw request"
    else
      transaction = Transaction.new
      transaction.status = Transaction.statuses[:pending]
      transaction.transaction_type = Transaction.transaction_types[:withdraw]
      transaction.source = Transaction.sources[:system]
      transaction.buyer = current_user
      transaction.amount = amount

      if transaction.save
        flash[:notice] = "Withdraw request sucessfully sent to revision"
      else
        flash[:alert] = "Withdraw request cannot be created"
      end
    end
    
    redirect_to request.referrer
  end

  def remove_subscription
    @subscription = Subscription.find_by_user_id(current_user.id)

    if @subscription.present? && @subscription.sub_id
      Stripe::Subscription.delete(@subscription.sub_id)
      return redirect_to request.referrer, notice: "Your subscription has been canceled"
    end
    return redirect_to request.referrer, alert: "Your subscription could not be canceled. Please contact the administrators"
  end
  

  private
  def current_user_params
    params.require(:user).permit(:from, :about, :status, :language, :avatar)
  end
end
