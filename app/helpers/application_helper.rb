module ApplicationHelper
  def avatar_url(user)
    if user.avatar.attached?
      url_for(user.avatar)
    else
      ActionController::Base.helpers.asset_path('icon_default_avatar.png')
    end
  end

  def design_cover(design)
    if design.photos.attached?
      url_for(design.photos[0])
    else
      ActionController::Base.helpers.asset_path('icon_default_image.png')
    end
  end
end
