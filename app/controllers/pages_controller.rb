class PagesController < ApplicationController
  def home
  end

  def search
    @categories = Category.all
    @category = Category.find(params[:category]) if params[:category].present?

    #@designs = Design.where("active = ? AND designs.title ILIKE ? AND category_id = ?", true, "%#{params[:q]}%", params[:category])

    @q = params[:q]

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

    @designs = Design.where(query_condition)
  end
end
