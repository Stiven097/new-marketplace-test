class Transaction < ApplicationRecord
    belongs_to :buyer, class_name: "User", optional: true
    belongs_to :seller, class_name: "User", optional: true
    belongs_to :design, optional: true
    belongs_to :request, optional: true

    enum status: [:approved, :pending, :rejected]
    enum transaction_type: [:trans, :withdraw]
    enum source: [:system, :stripe]
end
