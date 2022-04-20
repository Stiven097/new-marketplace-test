class Category < ApplicationRecord
  has_many :designs
  has_many :requests
end
