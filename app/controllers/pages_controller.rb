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
                      .select("designs.id, designs.title, designs.user_id, pricings.price AS price")
                      .joins(:pricings)
                      .where(query_condition)
                      .order(@sort)
  end
end
