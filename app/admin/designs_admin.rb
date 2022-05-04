Trestle.resource(:designs) do

  remove_action :new
  remove_action :destroy

  menu do
    item :designs, icon: "fa fa-address-card"
  end

  table do
    column :title
    column :active
    column :user, -> (obj) { obj.user.full_name }
    column :created_at, align: :center
    actions do |toolbar, instance, admin|
      toolbar.link 'Activate', admin.path(:activate, id: instance.id), method: :post, class: 'btn btn-success'
      toolbar.link 'Deactivate', admin.path(:deactivate, id: instance.id), method: :post, class: 'btn btn-danger'
    end
  end

  controller do
    def activate
      design = admin.find_instance(params)
      design.update(active: true)

      flash[:message] = "The design has been activated"
      redirect_to admin.path(:show, id: design)
    end

    def deactivate
      design = admin.find_instance(params)
      design.update(active: false)

      flash[:message] = "The design has been deactivated"
      redirect_to admin.path(:show, id: design)
    end
  end

  routes do
    post :activate, on: :member
    post :deactivate, on: :member
  end

  # Customize the form fields shown on the new/edit views.
  
  form do |design|
    text_field :title
    editor :description
    select :category_id, Category.where(active: true)
  end

  # search do |query|
  #   if query
  #     Design.where("title ILIKE", "%#{query}%", "%#{query}%")
  #   else
  #     Design.all
  #   end
    
  # end

end
