class OrdersController < ApplicationController
  before_action :authenticate_user!

  def create
    design = Design.find(params[:design_id])
    pricing = design.pricings.find_by(pricing_type: params[:pricing_type])

    if (pricing && !design.has_single_pricing) || (pricing && pricing.basic? && design.has_single_pricing)
      charge(design, pricing)
    else
      flash[:alert] = "The price is incorrect"
    end
    redirect_to request.referrer
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
    order.amount = pricing.price

    if order.save
      flash[:notice] = "Your order has been successfully created"
    else
      flash[:alert] = order.errors.full_messages.join(', ')
    end
  end
end
