class Review < ApplicationRecord
  belongs_to :order
  belongs_to :design, required: false
  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"
end
