class DesignsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_design, except: [:new, :create]
  before_action :is_authorised, only: [:edit, :update]
  before_action :set_step, only: [:update, :edit]

  def new
    @design = current_user.designs.build
    @categories = Category.all
  end

  def create
    @design = current_user.designs.build(design_params)

    if @design.save
      @design.pricings.create(Pricing.pricing_types.values.map{ |x| {pricing_type: x} })
      redirect_to edit_design_path(@design), notice: "Saved"
    else
      redirect_to request.referrer, flash: {error: @design.errors.full_messages}
    end
  end

  def edit
    @categories = Category.all
  end

  def update

    if @step == 2
      design_params[:pricings_attributes].each do |index, pricing|
        if @design.has_single_pricing && pricing[:pricing_type] != Pricing.pricing_types.key(0)
          next;
        else
          if pricing[:title].blank? || pricing[:description].blank? || pricing[:delivery_time].blank? || pricing[:price].blank?
            return redirect_to request.referrer, flash: {error: "Invalid pricing"}
          end
        end
      end
    end

    if @step == 3 && design_params[:description].blank?
      return redirect_to request.referrer, flash: {error: "Description cannot be blank."}
    end

    if @step == 4 && @design.photos.blank?
      return redirect_to request.referrer, flash: {error: "You don't have any photos."}
    end

    if @step == 5
      @design.pricings.each do |pricing|
        if @design.has_single_pricing && !pricing.basic?
          next;
        else
          if pricing[:title].blank? || pricing[:description].blank? || pricing[:delivery_time].blank? || pricing[:price].blank?
            return redirect_to edit_design_path(@design, step: 2), flash: {error: "Invalid pricing."}
          end
        end
      end

      if @design.description.blank?
        return redirect_to edit_design_path(@design, step: 3), flash: {error: "Description cannot be blank."}
      elsif @design.photos.blank?
        return redirect_to edit_design_path(@design, step: 4), flash: {error: "You don't have any photos."}
      end
    end

    if @design.update(design_params)
      flash[:notice] = "Saved!"
    else
      return redirect_to request.referrer, flash: {error: @design.errors.full_messages}
    end

    if @step < 5
      redirect_to edit_design_path(@design, step: @step + 1)
    else
      redirect_to dashboard_path
    end

  end

  def show
  end

  private

  def set_step
    @step = params[:step].to_i > 0 ? params[:step].to_i : 1
    if @step > 5
      @step = 5
    end
  end

  def set_design
    @design = Design.find(params[:id])
  end

  def is_authorised
    redirect_to root_path, alert: "You do not have permission" unless current_user.id == @design.user_id
  end

  def design_params
    params.require(:design).permit(:title, :video, :description, :active, :category_id, :has_single_pricing,
                                    pricings_attributes: [:id, :title, :description, :delivery_time, :price, :pricing_type])
  end
end
