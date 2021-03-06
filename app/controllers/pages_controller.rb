class PagesController < ApplicationController
  def home
  end

  def search
    @categories = Category.all
    @category = Category.find(params[:category]) if params[:category].present?

    #@designs = Design.where("active = ? AND designs.title ILIKE ? AND category_id = ?", true, "%#{params[:q]}%", params[:category])

    @q = params[:q]
    @min = params[:min]
    @max = params[:max]
    @delivery = params[:delivery].present? ? params[:delivery] : "0"
    @sort = params[:sort].present? ? params[:sort] : "price asc"

    query_condition = []
    query_condition[0] = "designs.active = true"
    query_condition[0] += " AND ((designs.has_single_pricing = true AND pricings.pricing_type = 0) OR (designs.has_single_pricing = false))"

    if !@q.blank?
      query_condition[0] += " AND designs.title ILIKE ?"
      query_condition.push "%#{@q}%"
    end

    if !params[:category].blank?
      query_condition[0] += " AND category_id = ?"
      query_condition.push params[:category]
    end

    if !params[:min].blank?
      query_condition[0] += " AND pricings.price >= ?"
      query_condition.push @min
    end

    if !params[:max].blank?
      query_condition[0] += " AND pricings.price <= ?"
      query_condition.push @max
    end

    if !params[:delivery].blank? && params[:delivery] != "0"
      query_condition[0] += " AND pricings.delivery_time <= ?"
      query_condition.push @delivery
    end

    @designs = Design
                      .select("designs.id, designs.title, designs.user_id, MIN(pricings.price) AS price")
                      .joins(:pricings)
                      .where(query_condition)
                      .group("designs.id")
                      .order(@sort)
                      .page(params[:page])
                      .per(6)
  end

  def calendar
    params[:start_date] ||= Date.current.to_s

    start_date = Date.parse(params[:start_date])
    first_of_month = (start_date - 1.month).beginning_of_month
    end_of_month = (start_date + 1.month).end_of_month

    @orders = Order.where("seller_id = ? AND status = ? AND due_date BETWEEN ? AND ?", 
                          current_user.id,
                          Order.statuses[:inprogress],
                          first_of_month,
                          end_of_month)
  end

  def plans
    @plans = Stripe::Plan.list(product: 'prod_LdSL0m53IiDVQn')
  end
end
