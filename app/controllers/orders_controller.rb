class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :is_authorised, only: [:show]

  def create
    design = Design.find(params[:design_id])
    pricing = design.pricings.find_by(pricing_type: params[:pricing_type])

    if (pricing && !design.has_single_pricing) || (pricing && pricing.basic? && design.has_single_pricing)
      if charge(design, pricing)
        return redirect_to buying_orders_path
      end
    else
      flash[:alert] = "The price is incorrect"
    end
    return redirect_to request.referrer
  end

  def selling_orders
    @orders = current_user.selling_orders
  end

  def buying_orders
    @orders = current_user.buying_orders
  end

  def complete
    @order = Order.find(params[:id])

    if !@order.completed?
      if @order.completed!
        flash[:notice] = "Your order has been completed"
      else
        flash[:alert] = "Something went wrong. Could not complete the order"
      end

      redirect_to request.referrer
    end
  end

  def show
    @order = Order.find(params[:id])
    @design = @order.design_id ? Design.find(@order.design_id) : nil
    @request = @order.request_id ? Request.find(@order.request_id) : nil
    @comments = Comment.where(order_id: params[:id])
  end
  

  private

  def is_authorised
    redirect_to dashboard_path, 
                alert: "You don't have permission" unless Order.where("id = ? AND (seller_id = ? OR buyer_id = ?)",
                                                                        params[:id], current_user.id, current_user.id)
  end
  

  def charge(design, pricing)

    subscription = Subscription.find_by_user_id(current_user.id)
    if subscription.present? && subscription.success?
      plan = Stripe::Plan.retrieve(subscription.plan_id)
      rate = plan.metadata.commission.to_f/100
    else
      rate = 10.0/100
    end

    amount = pricing.price * (rate + 1)

    order = design.orders.new
    order.due_date = Date.today() + pricing.delivery_time.days
    order.title = design.title
    order.seller_name = design.user.full_name
    order.seller_id = design.user.id
    order.buyer_name = current_user.full_name
    order.buyer_id = current_user.id
    order.amount = amount

    if params[:payment].blank?
      flash[:alert] = "No payment selected!"
      return false
    elsif params[:payment] == "system" 
      if amount > current_user.wallet
        flash[:alert] = "Not enough money"
        return false
      else
        ActiveRecord::Base.transaction do
          current_user.update!(wallet: current_user.wallet - amount)
          design.user.update!(wallet: design.user.wallet + pricing.price)
          Transaction.create! status: Transaction.statuses[:approved],
                              transaction_type: Transaction.transaction_types[:trans],
                              source: Transaction.sources[:system],
                              buyer: current_user,
                              seller: design.user,
                              amount: amount,
                              design: design
          order.save
        end
        flash[:notice] = "Your order has been successfully created"
        return true
      end
    else
      charge = Stripe::Charge.create({ 
        amount: (amount * 100).to_i,
        currency: "usd",
        customer: current_user.stripe_id,
        source: params[:payment]
      })

      if charge.paid
        ActiveRecord::Base.transaction do
          design.user.update!(wallet: design.user.wallet + pricing.price)
          Transaction.create! status: Transaction.statuses[:approved],
                              transaction_type: Transaction.transaction_types[:trans],
                              source: Transaction.sources[:stripe],
                              buyer: current_user,
                              seller: design.user,
                              amount: amount,
                              design: design
            order.save
        end
        flash[:notice] = "Your order has been successfully created"
        return true
      end
      flash[:alert] = "Invalid card"
      return false
    end

  rescue ActiveRecord::RecordInvalid
    flash[:alert] = "Something went wrong"
    return false
  end
end
