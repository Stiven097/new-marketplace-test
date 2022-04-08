class DesignsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_design, except: [:new, :create]
  before_action :is_authorised, only: [:edit, :update]

  def new
    @design = current_user.designs.build
    @category = Category.all
  end

  def create
    @design = current_user.designs.build(design_params)

    if @design.save
      @design.pricings.create(Pricing.pricing_types.values.map{ |x| {pricing_type: x} })
      redirect_to edit_design_path, notice: "Saved"
    else
      redirect_to request.referrer, flash: {error: @design.errors.full_messages}
    end
  end

  def edit
  end

  def update
  end

  def show
  end

  private

  def set_design
    @design = Design.find(params[:id])
  end

  def is_authorised
    redirect_to root_path, alert: "You do not have permission" unless current_user.id == @design.user_id
  end

  def design_params
    params.require(:desing).permit(:title, :video, :active, :category_id, :has_single_pricing,
                                    pricings_attributes: [:id, :title, :description, :delivery_time, :price, :pricing_type])
  end
end
