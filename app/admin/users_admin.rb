Trestle.resource(:users) do

  remove_action :destroy

  menu do
    item :users, icon: "fa fa-user"
  end

  table do
    column :full_name
    column :email
    column :active
    column :wallet
    column :paypal
    column :stripe_id
    column :created_at, align: :center
    actions do |toolbar, instance, admin|
      toolbar.link 'Activate', admin.path(:activate, id: instance.id), method: :post, class: 'btn btn-success'
      toolbar.link 'Deactivate', admin.path(:deactivate, id: instance.id), method: :post, class: 'btn btn-danger'
    end
  end

  controller do
    def activate
      user = admin.find_instance(params)
      user.update(active: true)

      flash[:message] = "The user has been activated"
      redirect_to admin.path(:show, id: user)
    end

    def deactivate
      user = admin.find_instance(params)
      user.update(active: false)

      flash[:message] = "The user has been deactivated"
      redirect_to admin.path(:show, id: user)
    end
  end

  routes do
    post :activate, on: :member
    post :deactivate, on: :member
  end

  # Customize the form fields shown on the new/edit views.
  
  form do |user|
    text_field :full_name
    text_field :paypal
    text_field :email
    text_area :about
  end

  search do |query|
    if query
      User.where("email ILIKE ? OR full_name ILIKE ?", "%#{query}%", "%#{query}%")
    else
      User.all
    end
  end

end
