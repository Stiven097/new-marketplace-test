class Order < ApplicationRecord
  belongs_to :design, required: false
  belongs_to :request, required: false

  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"

  has_many :reviews

  enum status: [:inprogress, :completed]
end
