class OrdersController < ApplicationController
  before_action :authenticate_user!

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

  private

  def charge(design, pricing)
    order = design.orders.new
    order.due_date = Date.today() + pricing.delivery_time.days
    order.title = design.title
    order.seller_name = design.user.full_name
    order.seller_id = design.user.id
    order.buyer_name = current_user.full_name
    order.buyer_id = current_user.id
    order.amount = pricing.price * 1.1

    amount = pricing.price * 1.1

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
